all: build
git:
	git add .
	git commit -m "update"
	git push -u
build:
	rst2html.py main.rst > index.html
