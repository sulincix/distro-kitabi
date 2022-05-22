all: build
git:
	git add .
	git commit -m "update"
	git push -u
build:
	rst2html main.rst > index.html
