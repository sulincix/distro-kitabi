all: build
git:
	git add .
	git commit -m "update"
	git push -u
build:
	find src -type f | sort -V | xargs cat > main.rst
	rst2html main.rst > index.html
