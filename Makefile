.PHONY: help verify check ci lint test

help: ## Show targets
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN { FS = ":.*## " } { printf "  %-8s %s\n", $$1, $$2 }'

verify: lint test ## Credential-free, non-mutating gate

check: verify ## Developer gate

ci: verify ## CI gate

lint: ## shellcheck, actionlint and both baseline checks
	shellcheck build.sh plan.sh smoke.sh lib/*.sh apps/*.sh download/*.sh tests/*.sh
	actionlint
	tests/check-baseline.sh
	tests/check-baseline-test.sh

test: ## Package planning and Debian metadata tests
	bash tests/run.sh
