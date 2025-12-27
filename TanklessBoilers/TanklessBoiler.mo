within TanklessBoilers;

model TanklessBoiler "Tankless boiler model with control inputs"
  
  import Modelica.Units.SI;
  
  // Fluid package
  replaceable package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater
    "Fluid medium";
  
  // Parameters (user-friendly units)
  parameter Real Q_max_kBTU = 120 "Maximum heat output (kBTU/h)"
    annotation(Dialog(group = "Heat Output"));
  parameter Real Q_min_kBTU = 15 "Minimum heat output (kBTU/h)"
    annotation(Dialog(group = "Heat Output"));
  parameter Real T_setpoint_F = 170 "Water temperature setpoint (°F)"
    annotation(Dialog(group = "Temperature"));
  parameter Real deadband_F = 10 "Hysteresis deadband (°F) - total width for setpoint control"
    annotation(Dialog(group = "Temperature"));
  parameter Real highLimit_F = 180 "High limit safety cutoff (°F)"
    annotation(Dialog(group = "Temperature"));
  parameter Real t_anti_short_cycle_min = 5.0 "Anti-short cycle delay time (minutes)"
    annotation(Dialog(group = "Temperature"));
  parameter Real t_min_run_sec = 60.0 "Minimum run time (seconds) - boiler must run at least this long"
    annotation(Dialog(group = "Temperature"));
  parameter Real T_ambient_F = 68.0 "Ambient temperature (°F) - for natural cooling (e.g., basement)"
    annotation(Dialog(group = "Temperature"));
  parameter Real m_flow_GPM = 5.0 "Primary loop flow rate (GPM)"
    annotation(Dialog(group = "Primary Loop"));
  parameter Real primaryLoopVolume_gal = 2.0 "Primary loop volume (gallons) - total water volume in closed primary loop"
    annotation(Dialog(group = "Primary Loop"));
  
  // Internal parameters (SI units)
  parameter SI.HeatFlowRate Q_max = Q_max_kBTU * 1000 * 1055.06 / 3600 
    "Maximum heat output (W)";
  parameter SI.HeatFlowRate Q_min = Q_min_kBTU * 1000 * 1055.06 / 3600 
    "Minimum heat output (W)";
  parameter SI.Temperature T_setpoint = (T_setpoint_F - 32) * 5/9 + 273.15 
    "Water temperature setpoint (K)";
  // Deadband conversion: for temperature differences, ΔT_K = ΔT_F * 5/9
  parameter SI.Temperature deadband = deadband_F * 5/9 
    "Hysteresis deadband (K)";
  parameter SI.Temperature highLimit = (highLimit_F - 32) * 5/9 + 273.15 
    "High limit safety cutoff (K)";
  parameter SI.Time t_anti_short_cycle = t_anti_short_cycle_min * 60 
    "Anti-short cycle delay time (s)";
  parameter SI.Time t_min_run = t_min_run_sec 
    "Minimum run time (s)";
  parameter SI.Temperature T_ambient = (T_ambient_F - 32) * 5/9 + 273.15
    "Ambient temperature (K)";
  parameter SI.Volume primaryLoopVolume = primaryLoopVolume_gal * 0.00378541
    "Primary loop volume (m³) - total water volume in closed primary loop";
  parameter SI.Density rho_nominal = Medium.density_pTX(
    Medium.p_default, Medium.T_default, Medium.X_default)
    "Nominal water density (kg/m3)";
  parameter SI.MassFlowRate m_flow_nominal = m_flow_GPM * 0.06309 
    "Nominal mass flow rate (kg/s) = GPM * 0.06309";
  parameter SI.VolumeFlowRate V_flow_nominal = m_flow_nominal / rho_nominal 
    "Nominal volume flow rate (m3/s)";
  parameter Real head_ft = 13.1 "Nominal pump head (feet)"
    annotation(Dialog(group = "Primary Loop"));
  parameter SI.Position head_nominal = head_ft * 0.3048 "Nominal pump head (m)";
  
  parameter Real eta = 0.96 "Efficiency (dimensionless) = 96% AFUE"
    annotation(Dialog(group = "Physical Properties"));
  parameter Real length_in = 39.37 "Boiler pipe length (inches)"
    annotation(Dialog(group = "Physical Properties"));
  parameter Real diameter_in = 1.97 "Boiler pipe diameter (inches)"
    annotation(Dialog(group = "Physical Properties"));
  parameter Integer nNodes = 3 "Number of nodes for thermal mass"
    annotation(Dialog(group = "Physical Properties"));
  
  // Internal SI parameters for physical dimensions
  parameter SI.Length length = length_in * 0.0254 "Boiler pipe length (m)";
  parameter SI.Diameter diameter = diameter_in * 0.0254 "Boiler pipe diameter (m)";
  
  // External fluid connectors for secondary loop
  Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare package Medium = Medium)
    "Supply port (hot water out to secondary loop)"
    annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));

  Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare package Medium = Medium)
    "Return port (cool water back from secondary loop)"
    annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));

  // Control input
  Modelica.Blocks.Interfaces.BooleanInput enable "On/off signal (true=on, false=off)"
    annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
  
  // Outputs (for monitoring)
  Modelica.Blocks.Interfaces.RealOutput Q_actual "Actual heat output (W)"
    annotation(Placement(transformation(extent = {{100, -30}, {120, -10}})));
  
  Modelica.Blocks.Interfaces.RealOutput m_flow "Mass flow rate (kg/s)"
    annotation(Placement(transformation(extent = {{100, -50}, {120, -30}})));
  
  Modelica.Blocks.Interfaces.RealOutput p_PSI "Pressure after pump (PSI)"
    annotation(Placement(transformation(extent = {{100, -70}, {120, -50}})));
  
  Modelica.Blocks.Interfaces.RealOutput T_inlet "Inlet water temperature (K)"
    annotation(Placement(transformation(extent = {{100, -90}, {120, -70}})));
  
  Modelica.Blocks.Interfaces.RealOutput T_outlet "Outlet water temperature (K)"
    annotation(Placement(transformation(extent = {{100, -110}, {120, -90}})));
  
  Modelica.Blocks.Interfaces.BooleanOutput highLimitTripped "High limit trip status"
    annotation(Placement(transformation(extent = {{100, 70}, {120, 90}})));

  // Internal components
  Modelica.Fluid.Pipes.DynamicPipe boilerPipe(
    redeclare package Medium = Medium,
    length = length,
    diameter = diameter,
    nNodes = nNodes,
    use_HeatTransfer = true)
    "Boiler pipe"
    annotation(Placement(transformation(extent = {{50, -10}, {70, 10}})));
  
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow heater
    "Heat source"
    annotation(Placement(transformation(extent = {{-10, 30}, {10, 50}})));
  
  Modelica.Thermal.HeatTransfer.Components.ThermalCollector heatCollector(m = nNodes)
    "Collect heat from pipe nodes"
    annotation(Placement(transformation(extent = {{-10, 10}, {10, 30}})));
  
  Modelica.Blocks.Logical.Switch enableSwitch
    "On/off switch: Q_max when enabled, 0 when disabled"
    annotation(Placement(transformation(extent = {{-30, -10}, {-10, 10}})));
  
  Modelica.Blocks.Sources.Constant maxHeat(k = Q_max)
    "Maximum heat output when enabled"
    annotation(Placement(transformation(extent = {{-60, 10}, {-40, 30}})));
  
  Modelica.Blocks.Sources.Constant zeroHeat(k = 0)
    "Zero heat when disabled"
    annotation(Placement(transformation(extent = {{-60, -30}, {-40, -10}})));
  
  // Setpoint controller (with hysteresis)
  SetpointController setpointController(
    T_setpoint = T_setpoint,
    deadband = deadband)
    "Setpoint control with hysteresis"
    annotation(Placement(transformation(extent = {{-40, 40}, {-20, 60}})));

  // High limit controller
  HighLimitController highLimitController(
    T_max = highLimit,
    t_anti_short_cycle = t_anti_short_cycle)
    "High limit control with anti-short cycle delay"
    annotation(Placement(transformation(extent = {{-40, 60}, {-20, 80}})));

  // Minimum run time controller
  MinimumRunTimeController minimumRunTimeController(
    t_min_run = t_min_run)
    "Minimum run time control (high limit can override)"
    annotation(Placement(transformation(extent = {{-40, 20}, {-20, 40}})));

  // Combine all enable conditions
  Modelica.Blocks.Logical.And setpointAndHighLimit
    "Combine setpoint OK and high limit OK"
    annotation(Placement(transformation(extent = {{-80, 50}, {-60, 70}})));

  Modelica.Blocks.Logical.And boilerWantsToFire
    "Signal indicating boiler wants to fire (external enable AND setpoint/high limit OK)"
    annotation(Placement(transformation(extent = {{-100, 20}, {-80, 40}})));

  Modelica.Blocks.Logical.Or boilerEnableWithMinRunTime
    "Boiler enable: wants to fire OR must stay on (min time)"
    annotation(Placement(transformation(extent = {{-40, 0}, {-20, 20}})));

  Modelica.Blocks.Logical.And boilerEnableLogic
    "Final enable logic: external enable AND setpoint OK AND high limit OK AND minimum run time OK"
    annotation(Placement(transformation(extent = {{-60, -60}, {-40, -40}})));
  
  Modelica.Fluid.Machines.PrescribedPump primaryPump(
    redeclare package Medium = Medium,
    redeclare function flowCharacteristic =
      Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow(
        V_flow_nominal = {0, V_flow_nominal, 1.5*V_flow_nominal},
        head_nominal = {2*head_nominal, head_nominal, 0}),
    rho_nominal = rho_nominal,
    N_nominal = 1500,
    use_N_in = true,
    V(displayUnit = "l") = 0.001)
    "Primary loop circulator pump (speed controlled by enable signal)"
    annotation(Placement(transformation(extent = {{-70, -10}, {-50, 10}})));

  Modelica.Blocks.Math.BooleanToReal pumpSpeedConverter
    "Convert enable signal to pump speed (1.0 = enabled, 0.0 = disabled)"
    annotation(Placement(transformation(extent = {{-100, 40}, {-80, 60}})));
  
  Modelica.Blocks.Math.Gain pumpSpeedGain(k = 1500)
    "Scale to pump nominal speed (1500 RPM when enabled, 0 RPM when disabled)"
    annotation(Placement(transformation(extent = {{-70, 40}, {-50, 60}})));
  
  Modelica.Fluid.Sensors.Pressure p_sensor(redeclare package Medium = Medium)
    "Pressure sensor after pump"
    annotation(Placement(transformation(extent = {{-40, -10}, {-20, 10}})));
  
  Modelica.Fluid.Sensors.Temperature T_inletSensor(redeclare package Medium = Medium)
    "Inlet temperature sensor (after pump)"
    annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
  
  Modelica.Fluid.Sensors.MassFlowRate m_flowSensor(redeclare package Medium = Medium)
    "Mass flow rate sensor"
    annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));
  
  Modelica.Fluid.Sensors.Temperature T_outletSensor(redeclare package Medium = Medium)
    "Outlet temperature sensor"
    annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));

  // Convert pressure from Pa to PSI (1 PSI = 6894.76 Pa)
  Modelica.Blocks.Math.Gain p_PSI_converter(k = 1/6894.76)
    "Convert pressure from Pa to PSI"
    annotation(Placement(transformation(extent = {{60, -60}, {80, -40}})));

  // Ambient heat transfer for natural cooling (using thermal conductor)
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor ambientConductor(G = 5.0)
    "Thermal conductor for ambient heat loss (e.g., basement at ~68°F)"
    annotation(Placement(transformation(extent = {{10, -60}, {30, -80}})));

  // Ambient temperature source (internal, no external connection needed)
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature ambientTemp(T = T_ambient)
    "Ambient temperature source (e.g., basement at ~68°F)"
    annotation(Placement(transformation(extent = {{40, -60}, {60, -80}})));

  // Return pipe to complete the closed loop (represents closely-spaced tees)
  Modelica.Fluid.Pipes.DynamicPipe closelySpacedTees(
    redeclare package Medium = Medium,
    length = 0.3,  // 30 cm short pipe
    diameter = diameter,
    nNodes = nNodes,
    modelStructure = Modelica.Fluid.Types.ModelStructure.a_v_b,
    use_HeatTransfer = true)
    "Return pipe completing primary loop (represents closely-spaced tees)"
    annotation(Placement(transformation(extent = {{-90, -10}, {-70, 10}})));

equation
  // Fluid connections for primary/secondary loop with closely spaced tees
  // Primary loop: port_b (secondary return) → closelySpacedTees → pump → sensors → boiler → sensors → port_a (secondary supply)
  // The closely-spaced tees allow the secondary loop to draw hot water and return cooler water

  // Primary loop: return from secondary loop through closely spaced tees to pump
  connect(port_b, closelySpacedTees.port_a)
    annotation(Line(points = {{-100, 0}, {-90, 0}}, color = {0, 127, 255}));

  connect(closelySpacedTees.port_b, primaryPump.port_a)
    annotation(Line(points = {{-70, 0}, {-70, 0}}, color = {0, 127, 255}));

  connect(primaryPump.port_b, p_sensor.port)
    annotation(Line(points = {{-50, 0}, {-40, 0}}, color = {0, 127, 255}));

  connect(p_sensor.port, T_inletSensor.port)
    annotation(Line(points = {{-20, 0}, {-10, 0}}, color = {0, 127, 255}));

  connect(T_inletSensor.port, m_flowSensor.port_a)
    annotation(Line(points = {{10, 0}, {20, 0}}, color = {0, 127, 255}));

  connect(m_flowSensor.port_b, boilerPipe.port_a)
    annotation(Line(points = {{40, 0}, {50, 0}}, color = {0, 127, 255}));

  connect(boilerPipe.port_b, T_outletSensor.port)
    annotation(Line(points = {{70, 0}, {90, 0}}, color = {0, 127, 255}));

  // Primary loop: supply hot water to secondary loop
  connect(T_outletSensor.port, port_a)
    annotation(Line(points = {{100, 0}, {100, 0}}, color = {0, 127, 255}));
  
  // Pump speed is controlled by the enable signal:
  // - When enable = true: pump runs at 1500 RPM (N_nominal)
  // - When enable = false: pump runs at 0 RPM (off)
  connect(enable, pumpSpeedConverter.u)
    annotation(Line(points = {{-120, 0}, {-110, 0}, {-110, 50}, {-102, 50}}, color = {255, 0, 255}));

  connect(pumpSpeedConverter.y, pumpSpeedGain.u)
    annotation(Line(points = {{-79, 50}, {-72, 50}}, color = {0, 0, 127}));

  connect(pumpSpeedGain.y, primaryPump.N_in)
    annotation(Line(points = {{-49, 50}, {-60, 50}, {-60, 10}}, color = {0, 0, 127}));
  
  // Heat transfer connections
  // Connect boiler pipe heat ports to both heater (via collector) and ambient convection
  connect(boilerPipe.heatPorts, heatCollector.port_a)
    annotation(Line(points = {{40, 5}, {40, 20}, {0, 20}, {0, 10}}, color = {191, 0, 0}));

  connect(heatCollector.port_b, heater.port)
    annotation(Line(points = {{0, 30}, {0, 40}}, color = {191, 0, 0}));

  // Connect ambient heat transfer for natural cooling (boiler pipe)
  connect(heatCollector.port_b, ambientConductor.port_a)
    annotation(Line(points = {{0, 30}, {0, 20}, {20, 20}, {20, -60}}, color = {191, 0, 0}));

  connect(ambientConductor.port_b, ambientTemp.port)
    annotation(Line(points = {{20, -80}, {20, -70}, {60, -70}}, color = {191, 0, 0}));

  // Connect ambient heat transfer for return pipe (connect all heat ports)
  connect(closelySpacedTees.heatPorts, heatCollector.port_a)
    annotation(Line(points = {{-80, -5}, {-80, -20}, {0, -20}, {0, 10}}, color = {191, 0, 0}));
  
  // Setpoint controller
  connect(T_inletSensor.T, setpointController.T_inlet)
    annotation(Line(points = {{0, 11}, {0, 30}, {-50, 30}, {-50, 50}, {-42, 50}}, color = {0, 0, 127}));

  // High limit controller
  connect(T_inletSensor.T, highLimitController.T_inlet)
    annotation(Line(points = {{0, 11}, {0, 40}, {-50, 40}, {-50, 70}, {-42, 70}}, color = {0, 0, 127}));

  // Combine setpoint and high limit conditions first
  connect(setpointController.setpointOK, setpointAndHighLimit.u1)
    annotation(Line(points = {{-19, 50}, {-82, 50}, {-82, 54}}, color = {255, 0, 255}));

  connect(highLimitController.highLimitOK, setpointAndHighLimit.u2)
    annotation(Line(points = {{-19, 70}, {-30, 70}, {-30, 66}, {-82, 66}}, color = {255, 0, 255}));

  // Create signal for when boiler wants to fire
  connect(enable, boilerWantsToFire.u1)
    annotation(Line(points = {{-120, 0}, {-110, 0}, {-110, 34}, {-102, 34}}, color = {255, 0, 255}));

  connect(setpointAndHighLimit.y, boilerWantsToFire.u2)
    annotation(Line(points = {{-59, 60}, {-110, 60}, {-110, 26}, {-102, 26}}, color = {255, 0, 255}));

  // Connect minimum run time controller - use feedback to track when boiler is actually firing
  // Connect boiler enable output back to minimum run time controller (creates feedback loop)
  connect(boilerEnableLogic.y, minimumRunTimeController.enable)
    annotation(Line(points = {{-39, -50}, {-50, -50}, {-50, 30}, {-42, 30}}, color = {255, 0, 255}));

  connect(highLimitController.highLimitTripped, minimumRunTimeController.highLimitTripped)
    annotation(Line(points = {{-19, 76}, {-30, 76}, {-30, 24}, {-42, 24}}, color = {255, 0, 255}));

  // Final enable logic: boiler wants to fire OR boiler must stay on (minimum run time)
  connect(boilerWantsToFire.y, boilerEnableWithMinRunTime.u1)
    annotation(Line(points = {{-79, 30}, {-70, 30}, {-70, 14}, {-42, 14}}, color = {255, 0, 255}));

  connect(minimumRunTimeController.mustStayOn, boilerEnableWithMinRunTime.u2)
    annotation(Line(points = {{-19, 30}, {-10, 30}, {-10, 6}, {-42, 6}}, color = {255, 0, 255}));

  // Final enable logic
  connect(enable, boilerEnableLogic.u1)
    annotation(Line(points = {{-120, 0}, {-100, 0}, {-100, -44}, {-62, -44}}, color = {255, 0, 255}));

  connect(boilerEnableWithMinRunTime.y, boilerEnableLogic.u2)
    annotation(Line(points = {{-19, 10}, {-10, 10}, {-10, -50}, {-62, -50}}, color = {255, 0, 255}));
  
  // Control logic: on/off switch - Q_max when enabled, 0 when disabled
  connect(maxHeat.y, enableSwitch.u1)
    annotation(Line(points = {{-39, 20}, {-32, 20}, {-32, 4}}, color = {0, 0, 127}));
  
  connect(zeroHeat.y, enableSwitch.u3)
    annotation(Line(points = {{-39, -20}, {-32, -20}, {-32, -4}}, color = {0, 0, 127}));
  
  connect(boilerEnableLogic.y, enableSwitch.u2)
    annotation(Line(points = {{-39, -50}, {-50, -50}, {-50, 0}, {-32, 0}}, color = {255, 0, 255}));
  
  connect(enableSwitch.y, heater.Q_flow)
    annotation(Line(points = {{-9, 0}, {0, 0}, {0, 40}}, color = {0, 0, 127}));
  
  // Outputs
  connect(enableSwitch.y, Q_actual)
    annotation(Line(points = {{-9, 0}, {80, 0}, {80, -20}, {110, -20}}, color = {0, 0, 127}));
  
  connect(m_flowSensor.m_flow, m_flow)
    annotation(Line(points = {{30, 11}, {30, -40}, {110, -40}}, color = {0, 0, 127}));
  
  // Convert pressure from Pa to PSI (1 PSI = 6894.76 Pa)
  connect(p_sensor.p, p_PSI_converter.u)
    annotation(Line(points = {{-30, 11}, {-30, -50}, {58, -50}}, color = {0, 0, 127}));
  
  connect(p_PSI_converter.y, p_PSI)
    annotation(Line(points = {{81, -50}, {110, -50}}, color = {0, 0, 127}));
  
  connect(T_inletSensor.T, T_inlet)
    annotation(Line(points = {{0, 11}, {0, -80}, {110, -80}}, color = {0, 0, 127}));
  
  connect(T_outletSensor.T, T_outlet)
    annotation(Line(points = {{100, 11}, {100, -100}, {110, -100}}, color = {0, 0, 127}));
  
  // High limit status output
  connect(highLimitController.highLimitTripped, highLimitTripped)
    annotation(Line(points = {{-19, 76}, {50, 76}, {50, 80}, {110, 80}}, color = {255, 0, 255}));

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 80}, {100, -80}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Polygon(points = {{-60, 60}, {-40, 40}, {-20, 60}, {0, 40}, {20, 60}, {40, 40}, {60, 60}, {60, -60}, {-60, -60}, {-60, 60}}, lineColor = {255, 0, 0}, fillColor = {255, 128, 128}, fillPattern = FillPattern.Solid),
      Text(extent = {{-80, 40}, {80, -40}}, textString = "Tankless\nBoiler", textColor = {0, 0, 0})}),
    Documentation(info = "<html>
    <p>
    A simple tankless boiler model with on/off control.
    </p>
    <p>
    Inputs:
    </p>
    <ul>
    <li><code>enable</code> - Boolean on/off signal (true=on, false=off)</li>
    </ul>
    <p>
    Outputs:
    </p>
    <ul>
    <li><code>Q_actual</code> - Actual heat output (W) - equals Q_max when on, 0 when off</li>
    <li><code>m_flow</code> - Mass flow rate (kg/s)</li>
    <li><code>T_inlet</code> - Inlet water temperature (K)</li>
    <li><code>T_outlet</code> - Outlet water temperature (K)</li>
    </ul>
    <p>
    <b>Primary Loop Architecture:</b><br/>
    The boiler includes an internal closed primary loop with its own pump that circulates water 
    through the boiler. The primary loop volume is configurable via the <code>primaryLoopVolume_gal</code>
    parameter (defaults to 2 gallons). The pump runs when the boiler is enabled (controlled by 
    the enable signal). The flow rate is configurable via the <code>m_flow_GPM</code> parameter.
    </p>
    <p>
    <b>Primary/Secondary Loop Architecture:</b><br/>
    The boiler includes external fluid ports (<code>port_a</code> and <code>port_b</code>) for connecting
    to a secondary (distribution) loop. The internal primary loop circulates water through the boiler
    and connects to the secondary loop through closely spaced tees. Hot water is supplied to the
    secondary loop via <code>port_a</code>, and cooler return water enters via <code>port_b</code>.
    The closely spaced tees ensure minimal mixing between primary and secondary flows.
    </p>
    <p>
           When enabled, the boiler outputs Q_max. When disabled, output is 0 W. The boiler will only fire
           when: (1) the external enable signal is true, (2) the setpoint controller indicates heat is needed
           (temperature below setpoint), and (3) the high limit is not tripped.
           </p>
    <p>
    <b>Setpoint Control with Hysteresis:</b><br/>
    The boiler uses setpoint control to maintain the desired water temperature. The boiler turns on
    when the inlet temperature drops below (T_setpoint_F - deadband_F/2) and turns off when it rises
    above (T_setpoint_F + deadband_F/2). The deadband provides hysteresis to prevent rapid on/off cycling.
    Default setpoint is 170°F with a 10°F deadband.
    </p>
    <p>
    <b>High Limit Control:</b><br/>
    The boiler includes high limit protection based on inlet water temperature. When the inlet
    temperature reaches or exceeds highLimit_F (default 180°F), the boiler shuts off and enters an
    anti-short cycle delay period (default 5 minutes). The boiler will not fire again until either:
    (1) the inlet temperature drops below highLimit_F, or (2) the anti-short cycle delay period completes
    (whichever comes first). The anti-short cycle delay prevents rapid cycling of the boiler. The high
    limit is a safety feature that takes precedence over setpoint control.
    </p>
    <p>
    <b>Control Logic:</b><br/>
    The boiler will only fire when ALL of the following conditions are met: (1) the external enable
    signal is true, (2) the setpoint controller indicates heat is needed (temperature below setpoint),
    and (3) the high limit is not tripped.
    </p>
    </html>"));
end TanklessBoiler;

