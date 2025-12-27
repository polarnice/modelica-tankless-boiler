.PHONY: help test clean run

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

run: ## Run primary-secondary loop example
	@echo "Running primary-secondary loop simulation..."
	@echo 'loadFile("TanklessBoilers/package.mo");' > build/run.mos
	@echo 'loadFile("TanklessBoilers/TanklessBoiler.mo");' >> build/run.mos
	@echo 'loadFile("TanklessBoilers/SetpointController.mo");' >> build/run.mos
	@echo 'loadFile("TanklessBoilers/HighLimitController.mo");' >> build/run.mos
	@echo 'loadFile("TanklessBoilers/MinimumRunTimeController.mo");' >> build/run.mos
	@echo 'loadFile("TanklessBoilers/Examples/package.mo");' >> build/run.mos
	@echo 'loadFile("TanklessBoilers/Examples/PrimarySecondaryBoilerTest.mo");' >> build/run.mos
	@echo 'simulate(TanklessBoilers.Examples.PrimarySecondaryBoilerTest);' >> build/run.mos
	@echo 'getErrorString();' >> build/run.mos
	@omc build/run.mos

test: run ## Run simulation test
	@echo "Simulation complete"

clean: ## Clean build artifacts
	@rm -rf build/
	@rm -f *.mat *.log *.json *.c *.o *.h *.makefile *.libs *.so *.fmu
	@rm -f TanklessBoilers/Examples/*.mat TanklessBoilers/Examples/*.log
	@rm -f TanklessBoilers.Examples.PrimarySecondaryBoilerTest*
	@echo "Cleaned build artifacts"

.DEFAULT_GOAL := help

