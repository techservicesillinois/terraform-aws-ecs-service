.PHONY: test tfc clean docker sh shell

REPO := $(shell basename $(shell git remote get-url origin) .git)

GOPTS := -lR . -e
GREP := grep $(GOPTS)
EGREP := egrep $(GOPTS)
SRCS := --include=*.tf
DOCS := --include=README.md

all: tfc test

tfc: .terraform
	@# Basic Terraform validation and formating checks
	terraform version
	terraform validate
	terraform fmt -check

# Create .terraform if does not exist
# A terraform init is requried to run a validate :-(
.terraform:
	terraform init -backend=false
	terraform version

test:
	@####################################################
	! $(EGREP) "TF-UPGRADE-TODO|cites-illinois|as-aws-modules" $(SRCS) $(DOCS)
	# Do NOT put terraform-aws in the title of the top-level README
	! grep "#\s*terraform-aws-" README.md
	# Do NOT use type string when you can use type number or bool!
#	! $(EGREP) '"\d+"|"true"|"false"' $(SRCS) $(DOCS)
	! $(EGREP) '"\d+"|"true"|"false"' $(SRCS)
	# Do NOT use old style maps in docs
	! $(EGREP) "\w+\s*\{" $(DOCS)
	# Do NOT drop the "s" in outputs.tf or variables.tf!
	! find . -name output.tf -o -name variable.tf | grep '.*'
	# Do NOT define an output in files other than outputs.tf
	! $(EGREP) 'output\s+"\w+"\s*\{' $(SRCS) --exclude=outputs.tf
	# Do NOT define a variable in files other than variables.tf
	! $(EGREP) 'variable\s+"\w+"\s*\{' $(SRCS) --exclude=variables.tf
	# DO put a badge in top-level README.md
	grep -q "\[\!\[Terraform actions status\]([^)]*$(REPO)/workflows/terraform/badge.svg)\]([^)]*$(REPO)/actions)" README.md
	# Do NOT split a source line over more than one line
	! $(GREP) 'source\s*=\s*$$' $(SRCS) $(DOCS)
	# Do NOT use ?ref= in source lines in a README.md!
	! $(GREP) 'source\s*=.*?ref=' $(DOCS)
	# Do NOT start a source line with git::
	! $(GREP) 'source\s*=\s*"git::' $(SRCS) $(DOCS)
	# Do NOT use .git in a source line
	! $(GREP) 'source\s*=.*\.git.*"' $(SRCS) $(DOCS)
	# Do NOT use double slashes with top-level modules
	! $(GREP) 'source\s*=.*//?ref=.*"' $(SRCS) $(DOCS)
	# Do NOT leave extra whitespace at the end of a line
	! $(EGREP) '\s+$$' $(SRCS)
	# Do NOT leave empty lines at the start or end of a file
	! find . -type f -name "*.tf" -exec sh -c "awk 'NR==1; END{print}' {} | egrep -q '^\s*$$' && echo {}" \; | grep '.*'
	@# Run tflint if it is installed
	@if which tflint >/dev/null; then tflint ; fi

# Launches the Makefile inside a container
docker:
	docker build . -t test/$(REPO)
	docker run --rm test/$(REPO)

# Create alias
sh: shell

# Launches the shell inside a container for debugging the Makefile
shell:
	docker build . -t test/$(REPO)
	docker run -it --rm --entrypoint=sh test/$(REPO)

clean:
	-rm -rf .terraform
	-docker rmi -f test/$(REPO) >/dev/null 2>&1
