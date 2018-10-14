#!/usr/bin/make
.DEFAULT_GOAL := help

COMMANDS_REQUIRED := git hugo
REQUIRED_COMMANDS := $(addprefix command-required-,${COMMANDS_REQUIRED})

HUGO_DOWNLOAD_URL = $(shell curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep browser_download_url | cut -d '"' -f 4 | \
	grep $(HUGO_OS)-64bit.tar.gz | grep -v extended)

THEME_DIR := themes/hugo-theme-learn

GIT_STATE:=$(shell test -z "$$(git status --porcelain)" || echo '-dirty')
GIT_COMMIT:=$(shell git rev-parse HEAD)
GIT_TAG:=$(shell git describe --exact-match --abbrev=0 2>/dev/null || echo 'dev')
GIT_BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	HUGO_OS := Linux
endif
ifeq ($(UNAME_S),Darwin)
	HUGO_OS := macOS
endif

################################ TARGETS #####################################
.PHONY: test
test:
	@echo $(HUGO_DOWNLOAD_URL)

.PHONY: theme-init
theme-init:
	git submodule init
	git submodule update

.PHONY: theme-update
theme-update:
	cd $(THEME_DIR) && \
	git checkout master && \
	git pull && \
	git add . && \
	[ git diff --staged --quiet ] || git commit -m "chore(theme): update theme"

.PHONY: clean
clean:
	rm -rf public && rm -rf resources

.PHONY: build
build: clean
	./bin/hugo --gc

.PHONY: dev
dev: clean
	open http://localhost:1313/
	./bin/hugo server --disableFastRender

.PHONY: tools
tools: download-hugo

.PHONY: download-hugo
download-hugo:
	mkdir -p bin
	cd bin && curl -sSL $(HUGO_DOWNLOAD_URL) | tar -xvzf - hugo

.PHONY: netlify-publish
netlify-publish: theme-init
	hugo

################################ MISC ########################################

.PHONY: commands-required
commands-required: $(REQUIRED_COMMANDS)

.PHONY: command-required-%s
command-required-%s:
	@test $$(command -v $* >/dev/null 2>&1) || { echo >&2 "Require $* but it's not installed.  Aborting."; exit 1; }
	#@test $$(command -v $*) || { echo "Missing required binary: $*" ; exit 1; }

.PHONY: help
help: commands-required ## show help for targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
