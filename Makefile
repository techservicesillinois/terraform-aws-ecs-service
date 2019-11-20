CONTAINER := terraform_modules_test

TESTDIRS := $(find . -type f -name '*.tf' | sed 's:^\.\/::;s:/[^/]*$::' | sort -u)

# Code Snippet Source:
#	https://stackoverflow.com/questions/38086185/how-to-check-if-a-program-is-run-in-bash-on-ubuntu-on-windows-and-not-just-plain
ifneq ($(shell grep -cE "(Microsoft|WSL)" /proc/version 2>/dev/null || echo 0), 0)
	HOME := /c/Users/$(USER)
endif

.PHONY: all ${TESTDIRS}

test: $(TESTDIRS)
	terraform fmt -write=false
	@test -z "$(shell terraform fmt -write=false)"

$(TESTDIRS):
	terraform validate -check-variables=false $@

behave: build
	docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm $(CONTAINER)

debug: build
	docker run -it -v $(HOME)/.aws:/root/.aws:ro --rm --entrypoint bash $(CONTAINER)

build:
	docker build . -t $(CONTAINER)

clean: 
	docker rmi $(CONTAINER)
