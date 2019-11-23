REPO := $(shell basename $(shell git remote get-url origin) .git)
CONTAINER := $(REPO)_test

# Code Snippet Source:
#	https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
ifneq ($(shell grep -cE "(Microsoft|WSL)" /proc/version 2>/dev/null || echo 0), 0)
	HOME := /c/Users/$(USER)
endif

.PHONY: all test debug build clean

all: build test

test:
	docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm $(CONTAINER)

debug:
	docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm --entrypoint bash $(CONTAINER)

build:
	docker build . -t $(CONTAINER)

clean: 
	docker rmi $(CONTAINER)
