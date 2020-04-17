build:
	jekyll serve -V -t -P 5654 --incremental

clean:
	rm -rf _site/*
	rm .jekyll-metadata