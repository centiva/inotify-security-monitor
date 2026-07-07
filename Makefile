.PHONY: lint test fmt install

lint:
	shellcheck -x scripts/*.sh installer/*.sh tests/*.sh

test:
	tests/smoke-test.sh

fmt:
	shfmt -w scripts installer tests

install:
	sudo ./installer/install.sh