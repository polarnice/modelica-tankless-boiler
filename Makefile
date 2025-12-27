.PHONY: help test clean run

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

run: ## Run primary-secondary loop example
	@echo "Running primary-secondary loop simulation..."
	@cd TanklessBoilers/Examples && omc PrimarySecondaryBoilerTest.mo

test: run ## Run simulation test
	@echo "Simulation complete"

clean: ## Clean build artifacts
	@rm -rf build/
	@rm -f *.mat *.log *.json *.c *.o *.h *.makefile *.libs
	@rm -f TanklessBoilers/Examples/*.mat TanklessBoilers/Examples/*.log
	@echo "Cleaned build artifacts"

.DEFAULT_GOAL := help

