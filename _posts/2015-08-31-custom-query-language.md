---
layout: post
title: A Custom Query Language
---

If you recall, our [CEP processor](http://blog.jonharrington.org/a-simple-cep-processor-in-elixir/) currently forces us to write elixir code to work on our windows of data, and our current implementation stores and operates on our data in the same function.

```
  def init({events, symbol}) do
    window = Window.timed(60)
    {:ok, %{symbol: symbol, events: events, window: window}}
  end
  
  def handle_cast({:tick, {symbol, timestamp, value}}, state) do
     w = Window.add(state.window, {timestamp, value})
     avg = Enum.sum(w)/Enum.count(w)
     GenEvent.sync_notify(state.events, {:avg, {symbol, timestamp, avg}})
     {:noreply, %{ state | window: w}}
   end
```

In a typical CEP application, the storing of incoming data is invisible to the end user and the code operating on it. Also, most (all?) CEP libraries and frameworks tend to provide a SQL like query language. In another system our operation code would be written like

```
insert into AverageStream
select symbol, avg(value) as average, timestamp
group by symbol
from TickStream#window.length(60)
```

If we squint a little we can see that the above code looks a lot like our Elixir Worker module.

CEP frameworks also tend to have the concept of streams of data, your code queries the stream and operates on the values returned. Streams are also usually defined using a SQL like define statement.

```
define table TickStream (symbol, timestamp, value)
define table AverageStream (symbol, timestamp, average)
```

Again, with a bit of squinting these definiations like a lot like elixir structs, so lets see what it takes to convert SQL like statements into Elixir code so we can add the same functionality to our CEP application.

## Lexing and Parsing

[Lex](https://en.wikipedia.org/wiki/Lex_(software)) and [Yacc](https://en.wikipedia.org/wiki/Yacc) are two well known and well understood pieces of software used by many languages to lex and parse text. I am not going to dive deep into compiler theory in this post (the internet is full of resources), I merely hope show how to use the erlang versions of lex ([leex](http://erlang.org/doc/man/leex.html)) and yac ([yecc](http://erlang.org/doc/man/yecc.html)) with elixir. 


To turn a statement such as

```
define table TickStream (symbol, timestamp, value)
```

into an elixir struct

```
defmodule TickStream do
	defstruct symbol: nil, timestamp: nil, value: nil
end   
```

we need to perform three steps, first, we need to tokenise it using leex, then we need to convert the tokens into an AST (abstract syntax tree) using yeec, and finally, we need to convert our AST to one that can be compiled by the elixir compiler.

### Leex
A lexer split our text into a series of tokens and associated metadata. To use leex, we need to create a s file that defines how we create tokens from text. A rule is simply:

```
regex: erlang code
```

**Note:** Leex and Yeec are erlang tools and expect code, atom names etc. to be written in erlang.

To make it easier to read, we can split our rules file into a definitions section, where we define our regular expressions, and a rules section, where we create our token tuples. Our rules must use erlang syntax and they must return a tuple of 

```
{token, Value}
```

Ok, so lets create our rules file in lib/lexer.xrl

```
Definitions.

KEYWORD    = [a-zA-Z_]+
WHITESPACE = [\s\t\n\r]

Rules.

define        : {token, {define, TokenLine, TokenChars}}.
table         : {token, {table, TokenLine, TokenChars}}.
{KEYWORD}     : {token, {keyword, TokenLine, TokenChars}}.
\(            : {token, {''('', TokenLine}}.
\)            : {token, {'')'', TokenLine}}.
,             : skip_token.
{WHITESPACE}+ : skip_token.

Erlang code.
```

The *Erlang code* section can be empty but the header must be present. Now lets try it out in a iex console

```
iex(1)> :leex.file(''lib/lexer.xrl'')
{:ok, ''lib/lexer.erl''}
iex(2)> c("lib/lexer.erl")
[:lexer]
iex(3)> {:ok, toks, _} = :lexer.string(''define table TickStream (symbol, timestamp, value)'')
{:ok,
 [{:define, 1, ''define''}, {:table, 1, ''table''}, {:keyword, 1, ''TickStream''},
  {:"(", 1}, {:keyword, 1, ''symbol''}, {:",", 1}, {:keyword, 1, ''timestamp''},
  {:",", 1}, {:keyword, 1, ''value''}, {:")", 1}], 1}
```

Great, we pass in a text string and get back a data structure. Now that we have our list of tokens, lets convert it into an AST.

### Yecc
Our next step is to convert the tokens we received from leex into an AST structure that we can process.

yecc also expects a rule file. A yecc rule is:

```
Left_hand_side -> Right_hand_side : Associated_code.    
```

The Erlang docs state: "The left hand side is a non-terminal category. The right hand side is a sequence of one or more non-terminal or terminal symbols with spaces between." 

I want to keep this code focused and hopefully the example will speak for itself, but basically a non-terminal is a category that is not full expanded, whereas a terminal is fully expanded (finished, "terminated"). In other words if you have a non-terminal you need to keep adding rules until you reach a terminal. Note the terminal names/tokens are those that are created by our lexer rules in the previous step.

In our associated code we use $1, $2, $3 etc. to reference items matched by our rule, the first item being $1 etc. Often we will simply ignore certain matched items as you will see below, they provide guidance to the human writer and the parser but are of little use after parsing.

```
Nonterminals definition name fields field.

Terminals define table keyword ''('' '')'' '',''.

Rootsymbol definition.

definition -> define table name ''('' fields '')'': {struct, ''$3'', {fields, ''$5''}}. % We are interested in the table and field names


name -> keyword: {name, extract(''$1'')}.

fields -> field: [''$1''].
fields -> field '','' fields: [''$1''] ++ ''$3''.

field -> keyword: extract(''$1'').


Erlang code.

extract({_, _, Value}) -> Value.
```

We declare a top level non-terminal, definition, as our entry point. We then say we expect a definition to have a defined format, define table <name> ..., when we see a group of tokens that matches that format, we can extract what we require. A lexer will lex any string of text that matches its rules, however, a parser will expect the text to have a certain *syntax*. It is the parser that will raise a syntax error if the format is wrong, not the lexer.

Ok, lets try it out

```
iex(4)> :yecc.file(''lib/parser.yrl'')
{:ok, ''lib/parser.erl''}
iex(5)> c("lib/parser.erl")
[:parser]
iex(6)> {:ok, ast} = :parser.parse(toks)
{:ok,
 {:struct, {:name, ''TickStream''}, {:fields, [''symbol'', ''timestamp'', ''value'']}}}
```

Now we have a datastructure that contains all we need to create an elixir struct.

## Elixir AST
Elixir has powerful metaprogramming support due to its use of macros. We can easily see the AST elixir is expecting by quoting our expected struct definition:

```
iex(1)> quote do
...(1)> defmodule TickStream do
...(1)>  defstruct symbol: nil, timestamp: nil, value: nil
...(1)>  end  
...(1)> end
{:defmodule, [context: Elixir, import: Kernel],
 [{:__aliases__, [alias: false], [:TickStream]},
  [do: {:defstruct, [context: Elixir, import: Kernel],
    [[symbol: nil, timestamp: nil, value: nil]]}]]}
```

We see what elixir expects is slightly more involved than what we currently produce, we now have two options. We can modify our parser rules to produce what elixir is expecting, or, we can use elixir code (functions) to modify our structure. 

In the long run the code approach gives us more flexibility so thats what I choose here (and elixir pattern matching makes it much easier once our transpilier/compilier gets more complex.)

Create a file called transformer.ex and add a function to convert the AST structure to an elixir AST data structure.

```
defmodule Transformer do

  def transform({:struct, {:name, name}, {:fields, fields}}) do
    stname = name |> List.to_atom
    stfields = fields |> Enum.map(fn(f) -> {List.to_atom(f), nil} end)

    {:defmodule, [context: Elixir, import: Kernel],
     [{:__aliases__, [alias: false], [stname]},
      [do: {:defstruct, [context: Elixir, import: Kernel],
        [stfields]}]]}
  end

end
```

We can test it in a console

```
iex(18)> c("lib/transformer.ex")
[Transformer]
iex(20)> exast = Transformer.transform(ast)
{:defmodule, [context: Elixir, import: Kernel],
 [{:__aliases__, [alias: false], [:TickStream]},
  [do: {:defstruct, [context: Elixir, import: Kernel],
    [[symbol: nil, timestamp: nil, value: nil]]}]]}
```

And see our function has converted our AST to the AST expected by the elixir compiler. Finally, lets compile and run it

```
iex(22)> Code.compile_quoted(exast)
[{TickStream,
  <<70, 79, 82, 49, 0, 0, 5, 0, 66, 69, 65, 77, 69, 120, 68, 99, 0, 0, 0, 99, 131, 104, 2, 100, 0, 14, 101, 108, 105, 120, 105, 114, 95, 100, 111, 99, 115, 95, 118, 49, 108, 0, 0, 0, 2, 104, 2, 100, 0, ...>>}]    
iex(23)> %TickStream{}
%TickStream{symbol: nil, timestamp: nil, value: nil}
iex(24)> %TickStream{symbol: "AAPL", timestamp: 100, value: 124.56}
%TickStream{symbol: "AAPL", timestamp: 100, value: 124.56}
```

As easy as that! We can now use the TickStream struct as if it had been written in pure elixir.

### Conclusion

In this post we have examined how to lex, parse and compile a custom language into elixir. The facts that erlang comes with leex and yeec as standard, and that elixir has powerful and easy to use code generation capabilities, means we have no excuse not to use these tools if a suitable use cases arises.
