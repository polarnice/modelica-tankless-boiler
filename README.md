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

### Running the Example

```bash
# Compile and run primary-secondary loop test
omc --simulate TanklessBoilers.Examples.PrimarySecondaryBoilerTest.mo

# Or use the Makefile
make primary
```

## Known Issues

- Primary-secondary example needs proper load modeling in secondary loop
- Common pipe between closely spaced tees should be added for realistic hydraulic behavior
- Expansion tank not yet included in examples

## License

MIT License - See LICENSE file for details

## References

- Siegenthaler, J. (2012). *Modern Hydronic Heating*. Cengage Learning.
- ASHRAE Handbook - HVAC Systems and Equipment

