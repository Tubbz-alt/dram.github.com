default: generate

.PHONY: generate serve publish clean

generate:
	tools/sources/generate

new:
	read NAME; touch _sources/posts/$$(date +"%Y-%m-%d")-$${NAME}.lml

serve:
	php -S 127.0.0.1:8000 tools/sources/serve.php

publish:
	- git branch -D master
	git co -b master
	make
	git add index.html blog/ logo/*.html
	git ci -m "Published."
	git push -f origin master
	git co sources

clean:
	rm -rf index.html blog/ logo/*.html
