SHELL=/bin/bash
all: build
git:
	git add .
	git commit -m "update"
	git push -u
build:
	find src -type f | sort -V | while read line ; do \
	    cat $$line ; \
	    echo -e "\n\n" ; \
	done > main.rst
	rst2html main.rst > index.html
