within TanklessBoilers.Examples;

model PrimarySecondaryBoilerTest "Test of TanklessBoiler with primary/secondary loop and closely spaced tees"
  extends Modelica.Icons.Example;
  import TanklessBoilers.*;
  import Modelica.Units.SI;
  // Fluid medium
  package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater;
  // System properties
  inner Modelica.Fluid.System system(energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial, p_ambient = 101325, T_ambient = 273.15 + 20) "System properties";
  // Tankless boiler (primary loop with internal closely spaced tees)
  TanklessBoiler boiler(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, qMaxKbtu = 120, tSetpointF = 170, highLimitF = 180, tAmbientF = 40, mFlowGpm = 5.0, primaryLoopVolumeGal = 2.0) "Tankless boiler with internal primary loop and closely spaced tees";
  // Secondary loop pump
  parameter SI.VolumeFlowRate V_flow_secondary = 0.000315 "Secondary pump nominal volume flow rate (5 GPM = 0.000315 m³/s)";
  parameter SI.Position head_secondary = 4.0 "Secondary pump nominal head (4 m = 13 ft)";
  Modelica.Fluid.Machines.PrescribedPump secondaryPump(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, rho_nominal = boiler.rho_nominal, N_nominal = 1500, use_N_in = true, redeclare function flowCharacteristic = Modelica.Fluid.Machines.BaseClasses.PumpCharacteristics.quadraticFlow(V_flow_nominal = {0, V_flow_secondary, 2*V_flow_secondary}, head_nominal = {2*head_secondary, head_secondary, 0})) "Secondary loop circulator pump" annotation(Placement(transformation(extent = {{80, -10}, {100, 10}})));
  // Secondary loop storage tank (50 gallon)
  Modelica.Fluid.Vessels.OpenTank storageTank(redeclare package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater, height = 1.2, crossArea = 0.126, level_start = 0.6, portsData = {Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter = 0.0254), Modelica.Fluid.Vessels.BaseClasses.VesselPortsData(diameter = 0.0254)}, nPorts = 2, use_HeatTransfer = true, T_start = 273.15 + 0) "50 gallon storage tank (189 liters) - starts at 32°F (0°C)" annotation(Placement(transformation(extent = {{60, 20}, {80, 40}})));
  // Ambient heat loss from storage tank
  // G = 100 W/K gives realistic heat loss for typical residential tank
  // At ΔT=10°F (5.6K): 100 × 5.6 = 560W ≈ 1900 BTU/hr (typical for 50-gal tank)
  // This should give ~3-5°F/hr heat loss, which is realistic
  Modelica.Thermal.HeatTransfer.Components.ThermalConductor tankHeatLoss(G = 100.0) "Heat loss from tank to ambient (typical residential insulation)" annotation(Placement(transformation(extent = {{60, 50}, {80, 70}})));
  Modelica.Thermal.HeatTransfer.Sources.FixedTemperature ambientTemp(T = 273.15 + 4.44) "Ambient temperature (40°F = 4.44°C)" annotation(Placement(transformation(extent = {{40, 50}, {60, 70}})));
  // Thermostat control - enable boiler and pump when tank temperature < 100°F
  parameter SI.Temperature T_setpoint_tank = 273.15 + 37.78 "Tank setpoint temperature (100°F = 37.78°C)";
  parameter SI.Temperature T_deadband = 2.78 "Deadband (5°F = 2.78K) - turn on at 100°F, turn off at 105°F";
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor tankTempSensor "Measure storage tank temperature" annotation(Placement(transformation(extent = {{60, 60}, {80, 80}})));
  // Hysteresis outputs true when input > uHigh, false when input < uLow
  // We want: enable (true) when T < 100°F, disable (false) when T > 105°F
  // So we use inverted logic: uLow = 100°F, uHigh = 105°F, then invert output
  Modelica.Blocks.Logical.Hysteresis thermostatHyst(uLow = T_setpoint_tank, uHigh = T_setpoint_tank + T_deadband) "Hysteresis: true when T > 105°F, false when T < 100°F" annotation(Placement(transformation(extent = {{90, 60}, {110, 80}})));
  Modelica.Blocks.Logical.Not invertThermostat "Invert to get: true when T < 100°F (call for heat)" annotation(Placement(transformation(extent = {{120, 60}, {140, 80}})));
  // Pump speed control
  Modelica.Blocks.Sources.Constant pumpSpeedOn(k = 1500) "Pump running speed" annotation(Placement(transformation(extent = {{80, 30}, {100, 50}})));
  Modelica.Blocks.Sources.Constant pumpSpeedOff(k = 0) "Pump stopped" annotation(Placement(transformation(extent = {{80, 10}, {100, 30}})));
  Modelica.Blocks.Logical.Switch pumpSpeedSwitch "Switch between ON and OFF speeds based on thermostat" annotation(Placement(transformation(extent = {{110, 20}, {130, 40}})));
  // SECONDARY LOOP CONNECTIONS
equation
  // Boiler supply (hot water) → secondary pump
  connect(boiler.port_a, secondaryPump.port_a);
  // Secondary pump → storage tank inlet (bottom port)
  connect(secondaryPump.port_b, storageTank.ports[1]);
  // Storage tank outlet (top port) → boiler return (cool water back)
  connect(storageTank.ports[2], boiler.port_b);
  // THERMAL CONNECTIONS
  // Storage tank heat loss to ambient
  connect(storageTank.heatPort, tankHeatLoss.port_a);
  connect(tankHeatLoss.port_b, ambientTemp.port);
  // Tank temperature sensor
  connect(storageTank.heatPort, tankTempSensor.port);
  // CONTROL CONNECTIONS
  // Thermostat control: monitor tank temperature and enable boiler + pump when < 100°F
  connect(tankTempSensor.T, thermostatHyst.u);
  connect(thermostatHyst.y, invertThermostat.u);
  connect(invertThermostat.y, boiler.enable);
  // Secondary pump speed control - same enable signal as boiler
  connect(invertThermostat.y, pumpSpeedSwitch.u2);
  connect(pumpSpeedOn.y, pumpSpeedSwitch.u1);
  connect(pumpSpeedOff.y, pumpSpeedSwitch.u3);
  connect(pumpSpeedSwitch.y, secondaryPump.N_in);
end PrimarySecondaryBoilerTest;
