.PHONY: help develop test
.DEFAULT_GOAL := help
help:
	@sed -ne 's/\(^[^#]*\):\s*##\(.*\)/\1\t\t\2/p' $(MAKEFILE_LIST)

develop:  ## prepare development environment
	-mkdir -p tests
	curl https://raw.githubusercontent.com/kward/shunit2/master/shunit2 > tests/shunit2

test:  ## run tests
	sh tests/test_tcr.sh
