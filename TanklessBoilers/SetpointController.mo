within TanklessBoilers;

model SetpointController "Setpoint control with hysteresis to prevent rapid cycling"
  import Modelica.Units.SI;
  // Constants
  constant Real kelvinOffset = 273.15 "Kelvin temperature offset";
  constant Real fToCScale = 5.0 / 9.0 "Fahrenheit to Celsius scale factor";
  constant Real defaultDeadbandF = 10.0 "Default deadband in Fahrenheit";
  // Parameters
  parameter SI.Temperature T_setpoint = kelvinOffset + 170 "Temperature setpoint (K)" annotation(Dialog(group = "Control"));
  parameter SI.Temperature deadband = defaultDeadbandF * fToCScale "Hysteresis deadband (K) - total width (on/off spread)" annotation(Dialog(group = "Control"));
  // Inputs
  Modelica.Blocks.Interfaces.RealInput T_inlet "Inlet water temperature (K)" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
  // Outputs
  Modelica.Blocks.Interfaces.BooleanOutput setpointOK "True if boiler should fire (temperature below setpoint + deadband/2)" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
  // Internal components - use Modelica.Blocks.Logical.Hysteresis for setpoint control
  // Standard hysteresis: false when u < uLow, true when u > uHigh (requires uHigh > uLow)
  // We want: true (need heat) when T < (setpoint - deadband/2), false (enough heat) when T > (setpoint + deadband/2)
  // Set: uLow = setpoint - deadband/2, uHigh = setpoint + deadband/2 (normal order)
  // This gives: false when T < (setpoint - deadband/2), true when T > (setpoint + deadband/2)
  // Then invert the output to get the desired behavior
  Modelica.Blocks.Logical.Hysteresis hysteresis(uLow = T_setpoint - deadband / 2, uHigh = T_setpoint + deadband / 2) "Hysteresis: false when T < (setpoint - deadband/2), true when T > (setpoint + deadband/2)" annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));
  Modelica.Blocks.Logical.Not invertOutput "Invert hysteresis output: true when T below setpoint (need heat)" annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));
equation
  // Connect inlet temperature to hysteresis input
  connect(T_inlet, hysteresis.u);
  // Invert output: true when temperature is below setpoint (should fire)
  connect(hysteresis.y, invertOutput.u);
  connect(invertOutput.y, setpointOK);
end SetpointController;
