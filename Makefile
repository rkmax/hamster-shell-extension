# Sphinx directories
SPHINX_BUILDDIR = _build
SPHINX_TEST_SPHINX_BUILDDIR = _test_build

# Directory to collect all sourc file to in order to build.
BUILDDIR = build

# Script to lauch a browser in order to open passed path.
define BROWSER_PYSCRIPT
import os, webbrowser, sys
try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

.PHONY: docs clean clean-test test

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "   clean"
	@echo "   clean-build		to clean the build directory of any leftovers."
	@echo "   clean-docs"
	@echo "	  clean-test		to clean all temporary data generate by tests."
	@echo "   collect			to collect all required files to the build directory."
	@echo "   coverage          to compute coverage and open html report in a browser."
	@echo "   compile			to compile file that needs to be shipped as a binary."
	@echo "   develop			to install (or update) all packages required for development"
	@echo "   dist				to package a release as a ready to deploy extension archive"
	@echo "   open-docs			to build and open the documentation"
	@echo "   test-docs			to run automated tests on the documentation."

clean: clean-build clean-docs clean-test clean-test
	rm -f dist/*

clean-build:
	rm -fr build

clean-docs:
	$(MAKE) -C docs clean SPHINX_BUILDDIR=$(SPHINX_BUILDDIR)

clean-test:
	$(MAKE) -C docs clean SPHINX_BUILDDIR=$(SPHINX_TEST_SPHINX_BUILDDIR)
	rm -fr tests/babel
	rm -fr coverage

collect:
	mkdir -p build
	cp -R extension/* $(BUILDDIR)
	cp -R data/* $(BUILDDIR)

compile:
	glib-compile-schemas $(BUILDDIR)/schemas
	find $(BUILDDIR) -name \*.po -execdir msgfmt hamster-shell-extension.po -o hamster-shell-extension.mo \;

coverage: test
	$(BROWSER) coverge/html-coverage/index.html

develop:
	pip install -U pip setuptools wheel
	pip install -U -r requirements.pip

dist: clean-build collect compile
# We need to do this like this as 'zip' always uses the cwd as archive root.
# And for the extension to work extension.js etc. need to be at the root.
	cd $(BUILDDIR); zip -rq ../dist/hamster@projecthamster.wordpress.com.zip ./*
	@ls -l dist

docs:
	$(MAKE) -C docs clean
	$(MAKE) -C docs html

open-docs: docs
	$(BROWSER) docs/_build/html/index.html

test:
	grunt

test-all: test-docs test

test-docs:
	make docs SPHINX_BUILDDIR=$(SPHINX_TEST_SPHINX_BUILDDIR) SPHINXOPTS='-W'
	make -C docs linkcheck SPHINX_BUILDDIR=$(SPHINX_TEST_SPHINX_BUILDDIR)

