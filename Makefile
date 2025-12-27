.PHONY: help test clean run plot setup lint

# Build directory for all artifacts
BUILD_DIR := build
RESULTS_DIR := results
VENV_DIR := .venv

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(RESULTS_DIR):
	@mkdir -p $(RESULTS_DIR)

run: $(BUILD_DIR) $(RESULTS_DIR) ## Run primary-secondary loop example
	@echo "Running primary-secondary loop simulation..."
	@echo 'loadModel(Modelica);' > $(BUILD_DIR)/run.mos
	@echo 'loadFile("TanklessBoilers/package.mo");' >> $(BUILD_DIR)/run.mos
	@echo 'checkModel(TanklessBoilers.Examples.PrimarySecondaryBoilerTest);' >> $(BUILD_DIR)/run.mos
	@echo 'cd("$(BUILD_DIR)");' >> $(BUILD_DIR)/run.mos
	@echo 'simulate(TanklessBoilers.Examples.PrimarySecondaryBoilerTest);' >> $(BUILD_DIR)/run.mos
	@echo 'getErrorString();' >> $(BUILD_DIR)/run.mos
	@omc $(BUILD_DIR)/run.mos 2>&1 | grep -v "^Warning:" | grep -v "^Notification:" | grep -v "^Error: Internal" || true
	@if [ -f $(BUILD_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat ]; then \
		mv $(BUILD_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat $(RESULTS_DIR)/; \
		echo ""; \
		echo "✓ Simulation completed successfully!"; \
		echo "  Results: $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat"; \
	else \
		echo ""; \
		echo "✗ Simulation failed - no results file generated"; \
		exit 1; \
	fi

plot: $(RESULTS_DIR) ## Generate plots from simulation results
	@if [ ! -f $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat ]; then \
		echo "Error: No results file found. Run 'make run' first."; \
		exit 1; \
	fi
	@echo "Generating plots..."
	@python3 plot_results.py $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat
	@if [ -f $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res_plots.png ]; then \
		echo "✓ Plots saved to $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res_plots.png"; \
	fi

test: run plot ## Run simulation and generate plots
	@echo ""
	@echo "✓ Test complete - simulation and plots generated"

setup: ## Setup development environment (install dependencies and git hooks)
	@echo "Setting up development environment..."
	@echo "Installing Python dependencies with uv..."
	@uv sync
	@echo "Installing TruffleHog..."
	@if ! command -v trufflehog &> /dev/null; then \
		curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b $(HOME)/.local/bin; \
	fi
	@echo "Installing git pre-commit hook..."
	@ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
	@echo "✓ Development environment setup complete!"
	@echo "  - Python venv: $(VENV_DIR)"
	@echo "  - TruffleHog installed to ~/.local/bin"
	@echo "  - Pre-commit hook installed"

lint: ## Run security scanning with TruffleHog
	@echo "Running TruffleHog security scan..."
	@trufflehog git file://. --only-verified --fail
	@echo "✓ No secrets detected"

clean: ## Clean build artifacts
	@rm -rf $(BUILD_DIR)/ $(RESULTS_DIR)/
	@rm -f *.mat *.log *.json *.c *.o *.h *.makefile *.libs *.so *.fmu *.xml
	@rm -f TanklessBoilers/Examples/*.mat TanklessBoilers/Examples/*.log
	@rm -f TanklessBoilers.Examples.PrimarySecondaryBoilerTest*
	@echo "✓ Cleaned build artifacts"

.DEFAULT_GOAL := help

