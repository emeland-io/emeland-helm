.PHONY: helm-deps helm-template helm-template-scenarios helm-test

SCENARIO_DIR ?= test-values
SCENARIO_FILES := $(sort $(wildcard $(SCENARIO_DIR)/*.yaml))

helm-deps:
	@helm dependency update emeland

helm-template: helm-deps
	@echo "==> Rendering default chart values"
	@helm template emeland emeland > /tmp/emeland-template-default.yaml
	@echo "PASS: default values"

helm-template-scenarios: helm-deps
	@if [ -z "$(SCENARIO_FILES)" ]; then echo "No scenario values files found in $(SCENARIO_DIR)"; exit 1; fi
	@set -e; \
	for file in $(SCENARIO_FILES); do \
		echo "==> Rendering $$file"; \
		helm template emeland emeland -f "$$file" > /tmp/emeland-template-$$(basename "$$file" .yaml).yaml; \
		echo "PASS: $$file"; \
	done; \
	echo "All scenario renders passed."

helm-test: helm-template helm-template-scenarios
