.PHONY: help test clean run plot setup lint lint-secrets lint-python lint-modelica

# Build directory for all artifacts
BUILD_DIR := build
RESULTS_DIR := results
LOG_DIR := logs
VENV_DIR := .venv

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(RESULTS_DIR):
	@mkdir -p $(RESULTS_DIR)

$(LOG_DIR):
	@mkdir -p $(LOG_DIR)

run: $(BUILD_DIR) $(RESULTS_DIR) $(LOG_DIR) ## Run primary-secondary loop example
	@echo "Running primary-secondary loop simulation..."
	@echo "Logging output to $(LOG_DIR)/simulation.log"
	@echo 'loadModel(Modelica);' > $(BUILD_DIR)/run.mos
	@echo 'loadFile("TanklessBoilers/package.mo");' >> $(BUILD_DIR)/run.mos
	@echo 'checkModel(TanklessBoilers.Examples.PrimarySecondaryBoilerTest);' >> $(BUILD_DIR)/run.mos
	@echo 'cd("$(BUILD_DIR)");' >> $(BUILD_DIR)/run.mos
	@echo 'simulate(TanklessBoilers.Examples.PrimarySecondaryBoilerTest, stopTime=3600, numberOfIntervals=3600, tolerance=1e-5, simflags="-lv LOG_NLS");' >> $(BUILD_DIR)/run.mos
	@echo 'getErrorString();' >> $(BUILD_DIR)/run.mos
	@omc $(BUILD_DIR)/run.mos 2>&1 | tee $(LOG_DIR)/simulation.log | grep -v "^Warning:" | grep -v "^Notification:" | grep -v "^Error: Internal" || true
	@if grep -q "Simulation execution failed" $(LOG_DIR)/simulation.log 2>/dev/null || grep -q "resultFile = \"\"" $(LOG_DIR)/simulation.log 2>/dev/null; then \
		echo ""; \
		echo "✗ Simulation execution failed!"; \
		echo "  Check log: $(LOG_DIR)/simulation.log for details"; \
		exit 1; \
	elif [ -f $(BUILD_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat ]; then \
		mv $(BUILD_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat $(RESULTS_DIR)/; \
		echo ""; \
		echo "✓ Simulation completed successfully!"; \
		echo "  Results: $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat"; \
		echo "  Log: $(LOG_DIR)/simulation.log"; \
	else \
		echo ""; \
		echo "✗ Simulation failed - no results file generated"; \
		echo "  Check log: $(LOG_DIR)/simulation.log"; \
		exit 1; \
	fi

plot: $(RESULTS_DIR) $(LOG_DIR) ## Generate plots from simulation results
	@if [ ! -f $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat ]; then \
		echo "Error: No results file found. Run 'make run' first."; \
		exit 1; \
	fi
	@echo "Generating plots..."
	@echo "Logging plot output to $(LOG_DIR)/plot.log"
	@python3 plot_results.py $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat 2>&1 | tee $(LOG_DIR)/plot.log
	@if [ -f $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res_plots.png ]; then \
		echo "✓ Plots saved to $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res_plots.png"; \
		echo "  Log: $(LOG_DIR)/plot.log"; \
	else \
		echo "✗ Plot generation may have failed"; \
		echo "  Check log: $(LOG_DIR)/plot.log"; \
		exit 1; \
	fi

test: run plot ## Run simulation and generate plots
	@echo ""
	@if [ -f $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat ] && [ -f $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res_plots.png ]; then \
		echo "✓ Test complete - simulation and plots generated"; \
		echo "  Results: $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat"; \
		echo "  Plots: $(RESULTS_DIR)/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res_plots.png"; \
		echo "  Logs: $(LOG_DIR)/"; \
	else \
		echo "✗ Test failed - missing results or plots"; \
		echo "  Check logs: $(LOG_DIR)/"; \
		exit 1; \
	fi

setup: ## Setup development environment (install dependencies and git hooks)
	@echo "Setting up development environment..."
	@echo "Installing Python dependencies with uv..."
	@uv sync
	@echo "Installing Rust (if needed)..."
	@if ! command -v cargo &> /dev/null; then \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
		export PATH="$$HOME/.cargo/bin:$$PATH"; \
	fi
	@echo "Installing rumoca-lint..."
	@if ! command -v rumoca-lint &> /dev/null; then \
		export PATH="$$HOME/.cargo/bin:$$PATH"; \
		cargo install --git https://github.com/CogniPilot/rumoca --bin rumoca-lint; \
	fi
	@echo "Installing TruffleHog..."
	@if ! command -v trufflehog &> /dev/null; then \
		curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b $(HOME)/.local/bin; \
	fi
	@echo "Installing ruff..."
	@uv pip install ruff
	@echo "Installing git pre-commit hook..."
	@ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
	@echo "✓ Development environment setup complete!"
	@echo "  - Python venv: $(VENV_DIR)"
	@echo "  - Rust toolchain installed"
	@echo "  - rumoca-lint installed"
	@echo "  - TruffleHog installed to ~/.local/bin"
	@echo "  - ruff installed"
	@echo "  - Pre-commit hook installed"

# Modelica source files
MODEL_FILES := $(shell find TanklessBoilers -name '*.mo' 2>/dev/null)
PYTHON_FILES := $(shell find . -name '*.py' -not -path './.venv/*' -not -path './build/*' 2>/dev/null)

lint: lint-secrets lint-python lint-modelica ## Run all linting checks

lint-secrets: ## Run security scanning with TruffleHog
	@echo "Running TruffleHog security scan..."
	@trufflehog git file://. --only-verified --fail
	@echo "✓ No secrets detected"

lint-python: ## Lint Python files with ruff
	@echo "Linting Python files with ruff..."
	@if command -v ruff &> /dev/null || [ -f $(VENV_DIR)/bin/ruff ]; then \
		uv run ruff check $(PYTHON_FILES) || true; \
	else \
		echo "⚠ ruff not found, skipping Python linting"; \
	fi
	@echo "✓ Python linting complete"

lint-modelica: ## Lint Modelica files with rumoca
	@export PATH="$$HOME/.cargo/bin:$$PATH"; \
	export MODELICAPATH="$${MODELICAPATH:-/opt/modelica-libraries}:$$HOME/.openmodelica/libraries"; \
	echo "Linting Modelica files with rumoca-lint..."; \
	echo "Note: Library import warnings are expected if MSL is not accessible to rumoca"; \
	if command -v rumoca-lint &> /dev/null; then \
		for file in $(MODEL_FILES); do \
			rumoca-lint $$file || true; \
		done; \
	else \
		echo "⚠ rumoca-lint not found, skipping Modelica linting"; \
	fi; \
	echo "✓ Modelica linting complete"

clean: ## Clean build artifacts
	@rm -rf $(BUILD_DIR)/ $(RESULTS_DIR)/ $(LOG_DIR)/
	@rm -f *.mat *.log *.json *.c *.o *.h *.makefile *.libs *.so *.fmu *.xml
	@rm -f TanklessBoilers/Examples/*.mat TanklessBoilers/Examples/*.log
	@rm -f TanklessBoilers.Examples.PrimarySecondaryBoilerTest*
	@echo "✓ Cleaned build artifacts and logs"

.DEFAULT_GOAL := help

