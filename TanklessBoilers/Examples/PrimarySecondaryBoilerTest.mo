within TanklessBoilers.Examples;

model PrimarySecondaryBoilerTest "Test of TanklessBoiler with primary/secondary loop and closely spaced tees"
  extends Modelica.Icons.Example;

  import TanklessBoilers.*;
  import Modelica.Units.SI;

  // Fluid medium
  package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater;

  // System properties
  inner Modelica.Fluid.System system(energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial,
    p_ambient = 101325, T_ambient = 273.15 + 20)
    "System properties";

  // Tankless boiler (primary loop with internal closely spaced tees)
  TanklessBoiler boiler(
    Q_max_kBTU = 120,
    T_setpoint_F = 170,
    highLimit_F = 180,
    T_ambient_F = 40,
    m_flow_GPM = 5.0,
    primaryLoopVolume_gal = 2.0,
    redeclare package Medium = Medium)
    "Tankless boiler with internal primary loop and closely spaced tees";

  // Secondary loop pump
  Modelica.Fluid.Machines.PrescribedPump secondaryPump(
    redeclare package Medium = Medium,
    redeclare function flowCharacteristic =
      Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow(
        V_flow_nominal = {0, 0.0005, 0.00075},
        head_nominal = {2*4.5, 4.5, 0}),
    rho_nominal = boiler.rho_nominal,
    N_nominal = 1500,
    use_N_in = true,
    V(displayUnit = "l") = 0.001)
    "Secondary loop circulator pump"
    annotation(Placement(transformation(extent = {{80, -10}, {100, 10}})));

  // Secondary loop storage tank (50 gallon)
  Modelica.Fluid.Vessels.OpenTank storageTank(
    redeclare package Medium = Medium,
    height = 1.2,
    crossArea = 0.126,
    level_start = 0.6,
    portsData = {
      Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter = 0.0254),
      Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter = 0.0254)},
    nPorts = 2,
    use_HeatTransfer = true,
    T_start = 273.15 + 0)
    "50 gallon storage tank (189 liters) - starts at 32°F (0°C)"
    annotation(Placement(transformation(extent = {{60, 20}, {80, 40}})));

  // Ambient heat loss from storage tank
  // G = 100 W/K gives realistic heat loss for typical residential tank
  // At ΔT=10°F (5.6K): 100 × 5.6 = 560W ≈ 1900 BTU/hr (typical for 50-gal tank)
  // This should give ~3-5°F/hr heat loss, which is realistic
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor tankHeatLoss(G = 100.0)
    "Heat loss from tank to ambient (typical residential insulation)"
    annotation(Placement(transformation(extent = {{60, 50}, {80, 70}})));

  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature ambientTemp(T = 273.15 + 4.44)
    "Ambient temperature (40°F = 4.44°C)"
    annotation(Placement(transformation(extent = {{40, 50}, {60, 70}})));

  // Flow control for secondary pump (runs for 18 minutes, then stops)
  Modelica.Blocks.Sources.Constant pumpSpeedOn(k = 1500)
    "Pump running speed"
    annotation(Placement(transformation(extent = {{80, 30}, {100, 50}})));
  
  Modelica.Blocks.Sources.Constant pumpSpeedOff(k = 0)
    "Pump stopped"
    annotation(Placement(transformation(extent = {{80, 10}, {100, 30}})));
  
  Modelica.Blocks.Sources.BooleanPulse pumpTimer(
    width = 49.72,
    period = 3600,
    startTime = 10)
    "Pump ON from 10s to 1800s (30 min), then OFF"
    annotation(Placement(transformation(extent = {{60, 20}, {80, 40}})));
  
  Modelica.Blocks.Logical.Switch pumpSpeedSwitch
    "Switch between ON and OFF speeds"
    annotation(Placement(transformation(extent = {{110, 20}, {130, 40}})));

  // Control signal - simple ON for 10 minutes then OFF
  Modelica.Blocks.Sources.BooleanStep enableStep(startTime = 600)
    "ON for first 10 minutes, then OFF"
    annotation(Placement(transformation(extent = {{-120, 40}, {-100, 60}})));
  
  Modelica.Blocks.Logical.Not notBlock
    "Invert: start with ON (true), turn OFF at 600s"
    annotation(Placement(transformation(extent = {{-100, 40}, {-80, 60}})));

equation
  // SECONDARY LOOP CONNECTIONS
  // Boiler supply (hot water) → secondary pump
  connect(boiler.port_a, secondaryPump.port_a)
    annotation(Line(points = {{100, 0}, {80, 0}}, color = {0, 127, 255}));

  // Secondary pump → storage tank inlet (bottom port)
  connect(secondaryPump.port_b, storageTank.ports[1])
    annotation(Line(points = {{100, 0}, {110, 0}, {110, 20}, {68, 20}}, color = {0, 127, 255}));

  // Storage tank outlet (top port) → boiler return (cool water back)
  connect(storageTank.ports[2], boiler.port_b)
    annotation(Line(points = {{72, 20}, {72, -20}, {-100, -20}, {-100, 0}}, color = {0, 127, 255}));

  // THERMAL CONNECTIONS
  // Storage tank heat loss to ambient
  connect(storageTank.heatPort, tankHeatLoss.port_a)
    annotation(Line(points = {{70, 40}, {70, 60}}, color = {191, 0, 0}));

  connect(tankHeatLoss.port_b, ambientTemp.port)
    annotation(Line(points = {{80, 60}, {60, 60}}, color = {191, 0, 0}));

  // CONTROL CONNECTIONS
  connect(enableStep.y, notBlock.u);
  connect(notBlock.y, boiler.enable);

  // Secondary pump speed control with timer
  // BooleanPulse: false initially, true during pulse, false after
  // Switch: when u2=false, output u3 (OFF); when u2=true, output u1 (ON)
  // Result: OFF for 10s, ON from 10s-1800s, OFF after 1800s
  connect(pumpTimer.y, pumpSpeedSwitch.u2);
  connect(pumpSpeedOn.y, pumpSpeedSwitch.u1);
  connect(pumpSpeedOff.y, pumpSpeedSwitch.u3);
  connect(pumpSpeedSwitch.y, secondaryPump.N_in);

  annotation(
    experiment(StartTime = 0, StopTime = 86400, Tolerance = 1e-6, Interval = 100),
    Documentation(info = "<html>
    <p>
    <b>Primary/Secondary Loop Boiler Test Model</b>
    </p>
    <p>
    This example demonstrates a tankless boiler with primary/secondary loop architecture.
    The system includes:
    </p>
    <ul>
    <li><b>Primary Loop:</b> Internal to the boiler with dedicated pump and closely spaced tees
        for hydraulic separation (built into the TanklessBoiler component)</li>
    <li><b>Secondary Loop:</b> Independent distribution system with its own pump and 50-gallon
        storage tank. Flow path: Boiler port_a → Pump → Tank → Boiler port_b</li>
    <li><b>Storage Tank:</b> 50-gallon open tank with heat loss to ambient, simulating
        thermal load on the system</li>
    </ul>
    <p>
    <b>How Hydraulic Separation Works:</b><br/>
    The boiler's internal closely spaced tees provide hydraulic decoupling between
    the primary and secondary loops, allowing each pump to operate independently.
    </p>
    <p>
    <b>System Operation:</b><br/>
    - Boiler primary pump: 5 GPM constant circulation (internal)<br/>
    - Secondary pump: 1500 RPM (approximately 3-4 GPM)<br/>
    - Storage tank loses heat to 20°C ambient<br/>
    - Boiler maintains 170°F setpoint with 180°F high limit<br/>
    - Observe temperature stratification in tank and heat transfer dynamics
    </p>
    </html>"));
end PrimarySecondaryBoilerTest;
