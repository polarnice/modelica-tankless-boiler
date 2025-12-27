# Modelica Tankless Boiler

A Modelica library for modeling tankless (on-demand) boilers with primary-secondary loop architecture.

## Overview

This library provides components for simulating tankless boiler systems commonly used in hydronic heating applications. The models include realistic control logic, thermal dynamics, and support for primary-secondary loop configurations with closely spaced tees.

## Features

- **TanklessBoiler**: Complete boiler model with:
  - Internal primary loop with circulator pump
  - Setpoint control with hysteresis
  - High-limit safety cutoff with anti-short-cycle protection
  - Minimum run time logic
  - Configurable heat output (kBTU/h)
  - Ambient heat loss modeling

- **Control Components**:
  - `SetpointController`: Temperature control with deadband
  - `HighLimitController`: Safety cutoff with time delays
  - `MinimumRunTimeController`: Prevents short cycling

- **Example Model**:
  - `PrimarySecondaryBoilerTest`: Complete primary-secondary loop system with closely spaced tees

## Primary-Secondary Loop Architecture

The primary-secondary loop design provides hydraulic separation between the boiler's internal circulation and the distribution system:

- **Primary Loop**: Internal to boiler, maintains constant flow through heat exchanger
- **Secondary Loop**: Distribution system with independent pump and flow rate
- **Closely Spaced Tees**: Provide hydraulic decoupling while maintaining thermal coupling

This architecture allows:
- Boiler to operate at optimal flow rate regardless of distribution needs
- Multiple secondary loops with different flow rates
- Protection of boiler from low-flow conditions

## Getting Started

### Prerequisites

- OpenModelica (for simulation)
- Python 3.10+ (for plotting)
- `uv` (Python package manager - installed automatically via `make setup`)
- Rust toolchain (installed automatically via `make setup` for Modelica linting)

### Initial Setup

1. Clone the repository
2. Run the setup command to install dependencies and git hooks:

```bash
make setup
```

This will:
- Install `uv` package manager (if not already installed)
- Create a Python virtual environment (`.venv/`)
- Install Python dependencies (matplotlib, numpy, dymat)
- Install Rust toolchain (for Modelica linting tools)
- Install `rumoca-fmt` and `rumoca-lint` (Modelica formatter and linter)
- Install `ruff` (Python linter)
- Install TruffleHog for secret scanning
- Set up the pre-commit git hook

### Development Workflow

```bash
make test    # Run simulation and generate plots
make run     # Run simulation only
make plot    # Generate plots from existing results
make lint    # Run all linting checks (secrets, Python, Modelica)
make clean   # Remove build artifacts
```

**Linting Targets:**
- `make lint` - Run all linting checks
- `make lint-secrets` - Scan for secrets with TruffleHog
- `make lint-python` - Lint Python files with ruff
- `make lint-modelica` - Format and lint Modelica files with rumoca

The pre-commit hook will automatically run `make lint` before each commit to check for secrets, Python issues, and Modelica code quality.

## Usage

The primary example demonstrates a complete primary-secondary loop system:

```modelica
// See TanklessBoilers/Examples/PrimarySecondaryBoilerTest.mo
model PrimarySecondaryBoilerTest
  TanklessBoiler boiler(
    Q_max_kBTU = 120,
    T_setpoint_F = 170,
    m_flow_GPM = 5.0);
  
  // Closely spaced tees for hydraulic separation
  Modelica.Fluid.Fittings.TeeJunctionIdeal supplyTee;
  Modelica.Fluid.Fittings.TeeJunctionIdeal returnTee;
  
  // Independent secondary pump
  Modelica.Fluid.Machines.PrescribedPump secondaryPump;
  
  // ... connections and control logic
end PrimarySecondaryBoilerTest;
```

For the complete implementation, see `TanklessBoilers/Examples/PrimarySecondaryBoilerTest.mo`.

## Parameters

### Boiler Configuration
- `Q_max_kBTU`: Maximum heat output (kBTU/h), default 120
- `Q_min_kBTU`: Minimum heat output (kBTU/h), default 15
- `T_setpoint_F`: Target water temperature (°F), default 170
- `highLimit_F`: Safety cutoff temperature (°F), default 180
- `deadband_F`: Control hysteresis (°F), default 10

### Primary Loop
- `m_flow_GPM`: Primary loop flow rate (GPM), default 5.0
- `primaryLoopVolume_gal`: Total water volume (gallons), default 2.0

### Control Timing
- `t_anti_short_cycle_min`: Delay after high-limit trip (minutes), default 5.0
- `t_min_run_sec`: Minimum firing duration (seconds), default 60.0

## Development

### Running Simulations

The project includes a Makefile for easy simulation and analysis:

```bash
# Show available commands
make help

# Run simulation only (results saved to results/ directory)
make run

# Generate plots from existing results
make plot

# Run simulation and generate plots (recommended)
make test

# Clean all build artifacts
make clean
```

### Output Structure

- `build/` - Temporary build artifacts (C files, object files, executables)
- `results/` - Simulation results (.mat files) and plots (.png files)
- Root directory stays clean!

### Plotting Results

The `plot_results.py` script generates comprehensive plots:
- Boiler heat output and temperatures
- Primary and secondary loop flow rates  
- Storage tank temperature and level
- Summary statistics

```bash
# Plot existing results
python3 plot_results.py results/TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat
```

## System Features

### Implemented
- ✅ Tankless boiler with on/off control
- ✅ Primary/secondary loop with closely spaced tees (using TeeJunctionVolume)
- ✅ Hydraulic separation between loops
- ✅ 50-gallon storage tank with heat loss
- ✅ Independent pump control for each loop
- ✅ High limit and setpoint control with anti-short cycle
- ✅ Minimum run time enforcement

## License

MIT License - See LICENSE file for details

## References

- Siegenthaler, J. (2012). *Modern Hydronic Heating*. Cengage Learning.
- ASHRAE Handbook - HVAC Systems and Equipment

