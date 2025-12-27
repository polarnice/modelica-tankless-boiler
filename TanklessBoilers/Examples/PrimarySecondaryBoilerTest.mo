within TanklessBoilers.Examples;

model PrimarySecondaryBoilerTest "Test of TanklessBoiler with primary/secondary loop and closely spaced tees"
  extends Modelica.Icons.Example;
  import TanklessBoilers.*;
  import Modelica.Units.SI;
  // Fluid medium
  package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater;
  // Initial condition constants (consistent with boiler internal components)
  constant SI.Temperature T_init = 293.15 "Initial temperature (20°C = 68°F)";
  constant SI.Pressure p_init = 101325 "Initial pressure (1 atm)";
  // System properties
  inner Modelica.Fluid.System system(energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, p_ambient = p_init, T_ambient = T_init) "System properties";
  // Tankless boiler (primary loop with internal closely spaced tees)
  TanklessBoiler boiler(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, qMaxKbtu = 120, tSetpointF = 170, highLimitF = 180, tAmbientF = 40, mFlowGpm = 5.0, primaryLoopVolumeGal = 2.0) "Tankless boiler with internal primary loop and closely spaced tees";
  // Secondary loop pump
  parameter SI.VolumeFlowRate V_flow_secondary = 0.000315 "Secondary pump nominal volume flow rate (5 GPM = 0.000315 m³/s)";
  parameter SI.Position head_secondary = 4.0 "Secondary pump nominal head (4 m = 13 ft)";
  Modelica.Fluid.Machines.PrescribedPump secondaryPump(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, rho_nominal = boiler.rho_nominal, N_nominal = 750, use_N_in = true, T_start = T_init, p_a_start = p_init, p_b_start = p_init, redeclare function flowCharacteristic = Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow(V_flow_nominal = {0, V_flow_secondary, 2*V_flow_secondary}, head_nominal = {2*head_secondary, head_secondary, 0})) "Secondary loop circulator pump (50% speed = 750 RPM)" annotation(Placement(transformation(extent = {{80, -10}, {100, 10}})));
  // Baseboard heating piping - 50 feet of 3/4" copper pipe
  parameter SI.Length baseboardLength = 15.24 "Baseboard piping length (50 ft = 15.24 m)";
  parameter SI.Diameter baseboardDiameter = 0.01905 "Baseboard pipe diameter (3/4 inch = 19.05 mm)";
  parameter Integer baseboardNodes = 10 "Number of nodes for baseboard thermal dynamics";
  Modelica.Fluid.Pipes.DynamicPipe baseboardPiping(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, length = baseboardLength, diameter = baseboardDiameter, nNodes = baseboardNodes, use_HeatTransfer = true, T_start = 273.15 + 60.0, p_a_start = p_init, p_b_start = p_init) "Baseboard heating piping - 100 ft of 1/2 inch copper, starts at 140°F (60°C)" annotation(Placement(transformation(extent = {{40, -10}, {60, 10}})));
  // Heat loss from baseboards to room with thermal mass
  parameter SI.Temperature T_room_initial = 273.15 + 18.3 "Initial room temperature (65°F = 18.3°C)";
  parameter SI.Temperature T_outside = 273.15 + 0.0 "Outside temperature (32°F = 0°C)";
  parameter Real baseboardUA = 950.0 "Baseboard heat transfer coefficient (W/K) - total for all baseboards";
  parameter SI.HeatCapacity roomThermalMass = 1e6 "Room thermal mass (J/K) - ~200 sq ft room with furnishings";
  parameter Real roomUA = 200.0 "Room heat loss to outside (W/K) - insulated room";
  Modelica.Thermal.HeatTransfer.Components.ThermalCollector baseboardHeatCollector(m = baseboardNodes) "Collects heat from all baseboard nodes" annotation(Placement(transformation(extent = {{40, 10}, {60, 30}})));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor baseboardHeatLoss(G = baseboardUA) "Heat transfer from baseboards to room" annotation(Placement(transformation(extent = {{60, 30}, {80, 50}})));
  Modelica.Thermal.HeatTransfer.Components.HeatCapacitor roomAir(C = roomThermalMass, T(start = T_room_initial, fixed = true)) "Room air thermal mass" annotation(Placement(transformation(extent = {{90, 50}, {110, 70}})));
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor roomHeatLoss(G = roomUA) "Heat loss from room to outside" annotation(Placement(transformation(extent = {{100, 30}, {120, 50}})));
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature outsideTemp(T = T_outside) "Outside temperature (32°F)" annotation(Placement(transformation(extent = {{140, 30}, {120, 50}})));
  // Thermostat control - enable boiler and pump when water temp < 135°F, turn off at 145°F (baseboard supply temp, ±5°F around 140°F)
  parameter SI.Temperature T_setpoint_tank = 273.15 + 57.22 "Baseboard supply setpoint temperature (135°F = 57.22°C) - turn on threshold";
  parameter SI.Temperature T_deadband = 5.56 "Deadband (10°F = 5.56K) - turn on at 135°F, turn off at 145°F (±5°F around 140°F)";
  // Hysteresis outputs true when input > uHigh, false when input < uLow
  // We want: enable (true) when T < 135°F, disable (false) when T > 145°F
  // So we use inverted logic: uLow = 135°F, uHigh = 145°F, then invert output
  Modelica.Blocks.Logical.Hysteresis thermostatHyst(uLow = T_setpoint_tank, uHigh = T_setpoint_tank + T_deadband) "Hysteresis: true when T > 145°F, false when T < 135°F" annotation(Placement(transformation(extent = {{90, 60}, {110, 80}})));
  Modelica.Blocks.Logical.Not invertThermostat "Invert to get: true when T < 135°F (call for heat)" annotation(Placement(transformation(extent = {{120, 60}, {140, 80}})));
  // Pump speed control
  Modelica.Blocks.Sources.Constant pumpSpeedOn(k = 750) "Pump running speed (50% of 1500 = 750 RPM)" annotation(Placement(transformation(extent = {{80, 30}, {100, 50}})));
  Modelica.Blocks.Sources.Constant pumpSpeedOff(k = 0) "Pump stopped" annotation(Placement(transformation(extent = {{80, 10}, {100, 30}})));
  Modelica.Blocks.Logical.Switch pumpSpeedSwitch "Switch between ON and OFF speeds based on thermostat" annotation(Placement(transformation(extent = {{110, 20}, {130, 40}})));
  // Fluid temperature sensor for baseboard supply (monitors water temp going to baseboards)
  Modelica.Fluid.Sensors.TemperatureTwoPort baseboardSupplyTempSensor(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater) "Baseboard supply temperature sensor" annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));
  // Expansion tank - provides pressure reference for the closed secondary loop
  // Using OpenTank to provide absolute pressure boundary (simulates gas-charged expansion tank)
  Modelica.Fluid.Vessels.OpenTank expansionTank(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, crossArea = 0.01, height = 0.3, level_start = 0.15, nPorts = 1, portsData = {Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter = 0.0127)}, T_start = T_init, p_ambient = p_init) "Expansion tank - provides pressure reference point (open to simulate gas cushion)" annotation(Placement(transformation(extent = {{110, -30}, {130, -10}})));
  // Tee junction to connect expansion tank
  Modelica.Fluid.Fittings.TeeJunctionVolume expansionTee(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, V = 0.0001, T_start = T_init, p_start = p_init) "Tee for expansion tank connection" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
  // SECONDARY LOOP CONNECTIONS
equation
  // Boiler supply (hot water) → secondary pump → expansion tee
  connect(boiler.port_a, secondaryPump.port_a);
  connect(secondaryPump.port_b, expansionTee.port_1);
  // Expansion tank connection
  connect(expansionTee.port_3, expansionTank.ports[1]);
  // Expansion tee → baseboard supply temp sensor → baseboard piping → boiler return
  connect(expansionTee.port_2, baseboardSupplyTempSensor.port_a);
  connect(baseboardSupplyTempSensor.port_b, baseboardPiping.port_a);
  connect(baseboardPiping.port_b, boiler.port_b);
  // HEAT TRANSFER CONNECTIONS
  // Baseboard piping heats room air, room air loses heat to outside
  connect(baseboardPiping.heatPorts, baseboardHeatCollector.port_a);
  connect(baseboardHeatCollector.port_b, baseboardHeatLoss.port_a);
  connect(baseboardHeatLoss.port_b, roomAir.port);
  connect(roomAir.port, roomHeatLoss.port_a);
  connect(roomHeatLoss.port_b, outsideTemp.port);
  // CONTROL CONNECTIONS
  // Thermostat control: monitor baseboard supply water temperature and enable boiler + pump when < 135°F (turn off at 145°F)
  connect(baseboardSupplyTempSensor.T, thermostatHyst.u);
  connect(thermostatHyst.y, invertThermostat.u);
  connect(invertThermostat.y, boiler.enable);
  // Secondary pump speed control - same enable signal as boiler
  connect(invertThermostat.y, pumpSpeedSwitch.u2);
  connect(pumpSpeedOn.y, pumpSpeedSwitch.u1);
  connect(pumpSpeedOff.y, pumpSpeedSwitch.u3);
  connect(pumpSpeedSwitch.y, secondaryPump.N_in);
end PrimarySecondaryBoilerTest;
