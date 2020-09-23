---
layout: post
title: PostGrest Introduction
---

I recently came across an interesting project called [PostgREST][postgrestws], an application that claimed to read the database schema of you''r PostgreSQL database and automatically create a "a cleaner, more standards-compliant, faster API than you are likely to write from scratch."
<!--excerpt-->

# Setup

Binaries are available for OS X and Linux on its [project page][postgrestws]. You will also need PostgreSQL installed, [PostgresApp][3] is an easy way to get up and running on OS X. Next lets create a simple database and populate it with some data. [Sqitch][4] is a great tool to manage database changes and we will use it for this post.

# How it works
PostgREST allows you to have multiple versions of your API and it assumes that each version is stored in a schema named after that version, so version 1 is in a schema named "1", version 2 in a schema named "2" etc. 

Obvioulsy, most production databases won''t have a schema named "1" so to expose your data using PostgREST we can create views in the "1" schema that serve up that data. I would strongly recommended that you do this for new projects also, a REST resource does not nessacarily have to be a one-to-one mapping to a row in a table and using views decouples our presentation layer from our storage format.

# Create a database
(First lets add a helpful git alias we will use for the post, *optional*)

	$ git config --global alias.add-commit ''!git add -A && git commit''

Next lets create a simple database with some tables and populate it with some data.

    $ createdb goodfilm
    $ git init .
    $ sqitch init goodfilm
	$ sqitch config core.engine pg
    $ sqitch target add production db:pg://localhost:5432/goodfilm
    $ sqitch engine add pg
    $ sqitch engine set-target pg production
	$ sqitch add appschmea -n ''Add schema for goodfilm objects''

deploy/appschmea.sql
```
-- Deploy appschmea
BEGIN;
create schema film;
COMMIT;
```
revert/appschmea.sql
```
-- Revert appschmea
BEGIN;
drop schema film;
COMMIT;
```

Deploy our changes

    $ sqitch deploy

And if that all worked lets add the change to version control.

	$ git add-commit -m "Adding goodfilm schema"

Now repeat the steps to add the goodfilm tables (normally you split this out into multiple files but we will use just the one here for brevity).

	$ sqitch add film -n "Add the goodfilm tables"

deploy/film.sql
```
- Deploy film

BEGIN;

CREATE TABLE film.director
(
  name text NOT NULL PRIMARY KEY
);

CREATE TABLE film.film
(
  id serial PRIMARY KEY,
  title text NOT NULL,
  year date NOT NULL,
  director text,
  rating real NOT NULL DEFAULT 0,
  language text NOT NULL,
  CONSTRAINT film_director_fkey FOREIGN KEY (director)
      REFERENCES film.director (name) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE film.festival
(
  name text NOT NULL PRIMARY KEY
);

CREATE TABLE film.competition
(
  id serial PRIMARY KEY,
  name text NOT NULL,
  festival text NOT NULL,
  year date NOT NULL,

  CONSTRAINT comp_festival_fkey FOREIGN KEY (festival)
      REFERENCES film.festival (name) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE film.nominations
(
  id serial PRIMARY KEY,
  competition integer NOT NULL,
  film integer NOT NULL,
  won boolean NOT NULL DEFAULT true,

  CONSTRAINT nomination_competition_fkey FOREIGN KEY (competition)
     REFERENCES film.competition (id) MATCH SIMPLE
     ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT nomination_film_fkey FOREIGN KEY (film)
     REFERENCES film.film (id) MATCH SIMPLE
     ON UPDATE NO ACTION ON DELETE NO ACTION
);

COMMIT;
```
revert/film.sql
```
-- Revert film

BEGIN;

DROP TABLE film.director CASCADE;
DROP TABLE film.film CASCADE;
DROP TABLE film.festival CASCADE;
DROP TABLE film.competition CASCADE;
DROP TABLE film.nominations CASCADE;

COMMIT;
```
    $ sqitch deploy
    $ git add-commit -m "Adding film table"

OK, now lets add some data and take a look around. For our dataset we are going to use the list of films nominated for the Venice Golden Lion and the Canne Palme d''Or over the last 20 years. Download the data file from this [gist](https://gist.github.com/prio/7d07a5cd840734342d35) and import it into the database:

    $ psql -d goodfilm < insert_data.sql

Now lets query the data

```
$ psql -d goodfilm
=# select title, rating from film.film limit 5;
        title        | rating
---------------------+--------
 Chuang ru zhe       |    6.2
 The Look of Silence |    8.3
 Fires on the Plain  |    5.8
 Far from Men        |    7.5
 Good Kill           |    6.1
(5 rows)

=# select * from film.nominations limit 5;
 id | competition | film | won
----+-------------+------+-----
  1 |           1 |    1 | f
  2 |           1 |    2 | f
  3 |           1 |    3 | f
  4 |           1 |    4 | f
  5 |           1 |    5 | f
(5 rows)
```

And lets get the top 5 rated films with their nominations
```
=# SELECT substring(f.title from 1 for 20) as title, c.name, f.rating from film.nominations as n
        LEFT JOIN film.film as f ON f.id=n.film
        LEFT JOIN film.competition as c ON c.id=n.competition 
        ORDER BY f.rating DESC
        limit 5;        
       title         |    name     | rating
----------------------+-------------+--------
 Winter Sleep         | Palme d''Or  |    8.5
 Mommy                | Palme d''Or  |    8.3
 The Look of Silence  | Golden Lion |    8.3
 Birdman: Or (The Une | Golden Lion |      8
 Sivas                | Golden Lion |    7.7
(5 rows)        
```

## Create an API

Now we will use PostGrest to create an API. We will expose three resources:

* **Film:** The list of films
* **Festival:** This will include the competions and nominations by year
* **Director:** Will include the list of films directed by that director

First we need to add a new schema

    $ sqitch add v1schema -m "Adding API v1 schema"

deploy/v1schema.sql
```
-- Deploy v1schema

BEGIN;
create schema "1";
COMMIT;
```
revert/v1schema.sql
```
-- Revert v1schema

BEGIN;
drop schema "1";
COMMIT;
```

Commit it, deploy it and add the files for our API

    $ git add-commit -m "Adding API v1 schema"
    $ sqitch deploy
    $ sqitch add v1views -m "Adding API v1 views"
    
And now we add the views we want to expose as our API. Again normally would would split these into seperate files/migrations but for brevity we will just use one set of files here

deploy/v1views.sql
```
-- Deploy v1views

BEGIN;

create or replace view "1".film as
select title, film.year, director, rating, language, comp.name as competition from film.film
 left join film.nominations as n on film.id = n.film
 left join film.competition as comp on n.competition = comp.id;

create or replace view "1".festival as
select comp.festival,
       comp.name as competition,
       comp.year,
       film.title,
       film.director,
       film.rating
 from film.nominations as noms
 left join film.film as film on noms.film = film.id
 left join film.competition as comp on noms.competition = comp.id
 order by comp.year desc, comp.festival, competition;

create or replace view "1".director as
select d.name, f.title, f.year, f.rating from film.director as d
 left join film.film as f on f.director = d.name;

COMMIT;
```
revert/v1views.sql
```
-- Revert v1views

BEGIN;
drop view "1".film;
drop view "1".director;
drop view "1".festival;
COMMIT;
```

Now lets deploy it and run PostGrest and take a look around

	$ sqitch deploy
    $ postgrest --db-host localhost --db-port 5432 --db-name goodfilm --db-pool 200 --anonymous $USER --port 3000 --db-user $USER           

**Note:** PostGrest error messages seem to be non-existant at the moment so if the command just exits make sure the correct users exist in your database and you are using the correct password, port etc.

Ok, if you view http://localhost:3000/ you should now see the three resources we have exposed.

```
$ curl -s http://localhost:3000/ | python -m json.tool
[
    {
        "insertable": false,
        "name": "director",
        "schema": "1"
    },
    {
        "insertable": false,
        "name": "festival",
        "schema": "1"
    },
    {
        "insertable": false,
        "name": "film",
        "schema": "1"
    }
]
```
Now lets try browsing around. First lets see what films nominated for awards last year have a rating greater than or equal to 8

```
$ curl -s "http://localhost:3000/festival?year=gte.2014-01-01&rating=gte.8" | python -m json.tool
[
    {
        "competition": "Palme d''Or",
        "director": "Xavier Dolan",
        "festival": "Cannes Film Festival",
        "rating": 8.3,
        "title": "Mommy",
        "year": "2014-01-01"
    },
    {
        "competition": "Palme d''Or",
        "director": "Nuri Bilge Ceylan",
        "festival": "Cannes Film Festival",
        "rating": 8.5,
        "title": "Winter Sleep",
        "year": "2014-01-01"
    },
    {
        "competition": "Golden Lion",
        "director": "Joshua Oppenheimer",
        "festival": "Venice Film Festival",
        "rating": 8.3,
        "title": "The Look of Silence",
        "year": "2014-01-01"
    },
    {
        "competition": "Golden Lion",
        "director": "Alejandro Gonz\u00e1lez I\u00f1\u00e1rritu",
        "festival": "Venice Film Festival",
        "rating": 8,
        "title": "Birdman: Or (The Unexpected Virtue of Ignorance)",
        "year": "2014-01-01"
    }
]
```

Excellent, a few to add to my watch list. I am a big fan of Japanese movies, so lets take a look at what Japanese movies were nominated last year.

```
$ curl -s "http://localhost:3000/film?year=gte.2014-01-01&language=eq.Japanese" | python -m json.tool
[
    {
        "competition": "Golden Lion",
        "director": "Shin''ya Tsukamoto",
        "language": "Japanese",
        "rating": 5.8,
        "title": "Fires on the Plain",
        "year": "2014-01-01"
    },
    {
        "competition": "Palme d''Or",
        "director": "Naomi Kawase",
        "language": "Japanese",
        "rating": 6.9,
        "title": "Still the Water",
        "year": "2014-01-01"
    }
]
```
Hmm, I haven''t seen either but the ratings aren''t very encouraging.

# Conclusion

I hope I have shown that PostgreSQL combined with PostGrest is a powerful combination that can give you a quick way to expose your data to other applications or web frontends. We have also seen how we can expose resources that don''t have an exact one to one relationship with a table. 

I think PostGrest is a project with a lot of promise, you now have one less reason to resort to storing your data it in a NoSQL database (because of the "free" REST API), so one less reason to give up all the benefits relational databases have to offer. I can also see a lot of uses for it when dealing with existing legacy databases.

[postgrestws]: https://github.com/begriffs/postgrest
[3]: http://postgresapp.com/
[4]: http://sqitch.org/
