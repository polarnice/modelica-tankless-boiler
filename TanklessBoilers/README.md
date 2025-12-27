# TanklessBoilers Modelica Library

A Modelica library providing reusable tankless boiler models for hydronic heating systems.

## Overview

This library contains models for simulating tankless (instantaneous) boilers commonly used in residential and commercial hydronic heating systems.

The boiler model is designed for use in a **primary loop** configuration, where the boiler inlet and outlet connect to closely spaced tees that hydraulically decouple the primary loop from the secondary (distribution) loop.

## Schematic

```mermaid
flowchart TD
    subgraph "TanklessBoiler Model - Internal Primary Loop"
        primaryVolume[Primary Loop Volume<br/>ports[1]&[2]: Primary<br/>ports[3]&[4]: Secondary]
        primaryVolume -->|ports[1]| pump[Primary Pump<br/>m_flow_GPM]
        pump --> p_sensor[Pressure Sensor<br/>p_PSI]
        p_sensor --> T_in[Temperature Sensor<br/>T_inlet]
        T_in --> m_flow_sensor[Mass Flow Sensor<br/>m_flow]
        m_flow_sensor --> boiler[Boiler Pipe<br/>Q_actual]
        boiler --> T_out[Temperature Sensor<br/>T_outlet]
        T_out -->|ports[2]| primaryVolume
        
        port_a[port_a<br/>Secondary Return] <-->|ports[3]| primaryVolume
        primaryVolume <-->|ports[4]| port_b[port_b<br/>Secondary Supply]
        
        enable[enable<br/>Control Input] -.->|On/Off| pump
        enable -.->|On/Off| boiler
        T_in -.->|T_inlet| setpoint_ctrl[Setpoint Controller<br/>T_setpoint_F, deadband_F]
        T_in -.->|T_inlet| high_limit_ctrl[High Limit Controller<br/>highLimit_F, t_anti_short_cycle_min]
        setpoint_ctrl -.->|setpointOK| boiler
        high_limit_ctrl -.->|highLimitOK| boiler
        high_limit_ctrl -.->|highLimitTripped| highLimitTripped[highLimitTripped<br/>Output]
    end
    
    style port_a fill:#e1f5ff
    style port_b fill:#e1f5ff
    style primaryVolume fill:#e8f4f8
    style enable fill:#fff4e1
    style pump fill:#ffe1f5
    style boiler fill:#ffcccc
    style setpoint_ctrl fill:#d4edda
    style high_limit_ctrl fill:#fff3cd
```

## Models

### `TanklessBoiler`

A simple tankless boiler model with on/off control:

- **Control input:**
  - `enable` - Boolean on/off signal (true=on, false=off)

- **Monitoring outputs:**
  - `Q_actual` - Actual heat output (W) - equals Q_max when on, 0 when off
  - `m_flow` - Mass flow rate (kg/s)
  - `p_PSI` - Pressure after pump (PSI)
  - `T_inlet` - Inlet water temperature (K)
  - `T_outlet` - Outlet water temperature (K)
  - `highLimitTripped` - High limit trip status (boolean)

- **Fluid connectors:**
  - `port_a` - Secondary loop return port (connects to primary loop volume at closely spaced tee)
  - `port_b` - Secondary loop supply port (connects to primary loop volume at closely spaced tee)

- **Parameters:**
  - `Q_max_kBTU` - Heat output when enabled (kBTU/h) - defaults to 120 kBTU/h
  - `Q_min_kBTU` - Minimum heat output (kBTU/h) - defaults to 15 kBTU/h, stored for reference
  - `T_setpoint_F` - Water temperature setpoint (°F) - defaults to 170°F
  - `deadband_F` - Hysteresis deadband (°F) - defaults to 10°F, prevents rapid cycling
  - `highLimit_F` - High limit safety cutoff (°F) - defaults to 180°F
  - `t_anti_short_cycle_min` - Anti-short cycle delay (minutes) - defaults to 5.0 minutes
  - `t_min_run_sec` - Minimum run time (seconds) - defaults to 60.0 seconds
  - `T_ambient_F` - Ambient temperature (°F) - defaults to 68°F (typical basement)
  - `m_flow_GPM` - Primary loop flow rate (GPM) - defaults to 5.0 GPM
  - `primaryLoopVolume_gal` - Primary loop volume (gallons) - defaults to 2.0 gallons
  - `head_ft` - Nominal pump head (feet) - defaults to 13.1 ft (4 m)
  - `eta` - Efficiency (dimensionless) - defaults to 0.96 (96% AFUE)
  - `length_in`, `diameter_in` - Physical dimensions (inches) - defaults: 39.4 in length, 2.0 in diameter
  - `nNodes` - Number of nodes for thermal mass

The boiler includes an internal primary loop pump that runs whenever the boiler is enabled.

## Usage

```modelica
import TanklessBoilers.*;

TanklessBoiler boiler(
  Q_max_kBTU = 120,      // Heat output when on (kBTU/h)
  T_setpoint_F = 170,    // Water temperature setpoint (°F)
  highLimit_F = 180,     // High limit safety cutoff (°F)
  deadband_F = 10,       // Hysteresis deadband (°F)
  m_flow_GPM = 5.0       // Primary loop flow rate (GPM)
);

// Connect secondary loop (example: simple pipe for testing)
// In a real system, this would connect to distribution zones
// Note: Closed loops need a pressure reference (e.g., expansion tank)
StaticPipe secondaryLoopPipe(...);
OpenTank expansionTank(...);  // Provides pressure reference

connect(boiler.port_b, secondaryLoopPipe.port_a);
connect(secondaryLoopPipe.port_b, expansionTank.ports[1]);
connect(expansionTank.ports[2], boiler.port_a);

// Connect control signal
connect(enable.y, boiler.enable);  // true=on, false=off
```

**Primary Loop Architecture:**
The boiler includes an internal closed primary loop with a dedicated circulator pump. The primary loop volume is represented by a `ClosedVolume` with 4 ports:
- Ports[1] and [2]: Primary loop circulation (pump → boiler → return)
- Ports[3] and [4]: Secondary loop connections (closely spaced tees)
  - Port[3]: Secondary return (`port_a`)
  - Port[4]: Secondary supply (`port_b`)

**Behavior:**
- The boiler maintains the setpoint temperature (`T_setpoint_F`) with hysteresis control
- Boiler turns ON when inlet temperature < (setpoint - deadband/2)
- Boiler turns OFF when inlet temperature > (setpoint + deadband/2)
- High limit (`highLimit_F`) provides safety protection - boiler shuts off if temperature exceeds this limit
- Minimum run time (`t_min_run_sec`) prevents short cycling - boiler runs for at least this duration once started
- When `enable = false`: Boiler outputs 0 W (off)
- Primary pump runs whenever the boiler is enabled

## Examples

- `TanklessBoilers.Examples.PrimarySecondaryBoilerTest` - Complete primary-secondary loop system with closely spaced tees demonstrating hydraulic separation between boiler and distribution loops

## Requirements

- Modelica Standard Library 4.0.0 or later

## License

[Add your license here]

