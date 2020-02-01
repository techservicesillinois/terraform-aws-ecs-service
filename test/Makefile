REPO := $(shell basename $(shell git remote get-url origin) .git)
ACCOUNT := 224588347132
CONTAINER := $(REPO)-tests

# Code Snippet Source:
#	https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
ifneq ($(shell grep -cE "(Microsoft|WSL)" /proc/version 2>/dev/null || echo 0), 0)
	HOME := /c/Users/$(USER)
endif

.PHONY: all test debug login build clean

all: test

test: login build
	docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm $(CONTAINER)

debug: login
	docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm --entrypoint bash $(CONTAINER)

login:
	@aws sts get-caller-identity 2>/dev/null | grep -q $(ACCOUNT)\
	 || (echo "ERROR: Not logged into AWS account $(ACCOUNT)"; exit 1)

build: .$(CONTAINER)
.$(CONTAINER):
	docker build .. -t $(CONTAINER) -f Dockerfile

clean: 
	docker rmi $(CONTAINER)
