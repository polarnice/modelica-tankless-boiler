.PHONY: help test clean simple primary

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

simple: ## Run simple boiler test
	@./scripts/run_simple_test.sh

primary: ## Run primary-secondary loop test
	@./scripts/run_primary_secondary_test.sh

test: simple ## Run all tests
	@echo "All tests complete"

clean: ## Clean build artifacts
	@rm -rf build/
	@rm -f *.mat *.log *.json
	@echo "Cleaned build artifacts"

.DEFAULT_GOAL := help

