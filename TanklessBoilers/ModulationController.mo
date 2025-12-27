within TanklessBoilers;

model ModulationController "Proportional modulation controller based on inlet temperature"
  import Modelica.Units.SI;
  // Constants
  constant Real kelvinOffset = 273.15 "Kelvin temperature offset";
  constant Real fToCScale = 5.0 / 9.0 "Fahrenheit to Celsius scale factor";
  // Parameters
  parameter SI.Temperature T_setpoint = kelvinOffset + 170 "Temperature setpoint (K)" annotation(Dialog(group = "Control"));
  parameter SI.HeatFlowRate Q_min = 15.0 * 1000 * 1055.06 / 3600 "Minimum heat output (W)" annotation(Dialog(group = "Heat Output"));
  parameter SI.HeatFlowRate Q_max = 120.0 * 1000 * 1055.06 / 3600 "Maximum heat output (W)" annotation(Dialog(group = "Heat Output"));
  parameter SI.Temperature modulationRange = 20.0 * fToCScale "Temperature range over which modulation occurs (K) - modulates from Q_max at (T_setpoint - modulationRange) to Q_min at T_setpoint" annotation(Dialog(group = "Control"));
  // Inputs
  Modelica.Blocks.Interfaces.RealInput T_inlet "Inlet water temperature (K)" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
  // Outputs
  Modelica.Blocks.Interfaces.RealOutput Q_modulated "Modulated heat output (W) - varies between Q_min and Q_max" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
  // Internal components
  // Proportional control: Q = Q_min + (Q_max - Q_min) * (1 - normalized_temp)
  // normalized_temp = clamp((T_inlet - (T_setpoint - modulationRange)) / modulationRange, 0, 1)
  // When T_inlet = T_setpoint - modulationRange: normalized_temp = 0, Q = Q_max
  // When T_inlet = T_setpoint: normalized_temp = 1, Q = Q_min
  Modelica.Blocks.Math.Add tempOffset "Calculate T_inlet - (T_setpoint - modulationRange)" annotation(Placement(transformation(extent = {{-60, -10}, {-40, 10}})));
  Modelica.Blocks.Sources.Constant setpointOffset(k = -(T_setpoint - modulationRange)) "Negative of lower bound for subtraction" annotation(Placement(transformation(extent = {{-100, -30}, {-80, -10}})));
  Modelica.Blocks.Math.Division normalizeTemp "Normalize temperature to 0-1 range" annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));
  Modelica.Blocks.Sources.Constant rangeConstant(k = modulationRange) "Modulation range for normalization" annotation(Placement(transformation(extent = {{-60, -30}, {-40, -10}})));
  Modelica.Blocks.Nonlinear.Limiter limiter(uMax = 1.0, uMin = 0.0) "Clamp normalized temperature to 0-1" annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));
  Modelica.Blocks.Math.Add invertSignal(k1 = 1.0, k2 = -1.0) "Calculate 1 - normalized_temp (so low temp = high output)" annotation(Placement(transformation(extent = {{60, -10}, {80, 10}})));
  Modelica.Blocks.Sources.Constant oneConstant(k = 1.0) "Constant 1 for inversion" annotation(Placement(transformation(extent = {{40, -30}, {60, -10}})));
  Modelica.Blocks.Math.Product scaleToRange "Scale to Q_min to Q_max range" annotation(Placement(transformation(extent = {{80, -10}, {100, 10}})));
  Modelica.Blocks.Math.Add addQMin(k2 = Q_min) "Add Q_min to get final output" annotation(Placement(transformation(extent = {{100, -30}, {120, -10}})));
  Modelica.Blocks.Sources.Constant qRangeConstant(k = Q_max - Q_min) "Q_max - Q_min for scaling" annotation(Placement(transformation(extent = {{60, -30}, {80, -10}})));
  Modelica.Blocks.Sources.Constant oneForQMin(k = 1.0) "Constant 1.0 to multiply with Q_min" annotation(Placement(transformation(extent = {{80, -30}, {100, -10}})));
equation
  // Calculate temperature offset from lower bound: T_inlet - (T_setpoint - modulationRange)
  connect(T_inlet, tempOffset.u1);
  connect(setpointOffset.y, tempOffset.u2);
  // Normalize to 0-1 range
  connect(tempOffset.y, normalizeTemp.u1);
  connect(rangeConstant.y, normalizeTemp.u2);
  // Clamp to 0-1
  connect(normalizeTemp.y, limiter.u);
  // Invert: we want high output when temp is low
  // normalized_temp = 0 (cold) -> we want 1.0 -> Q_max
  // normalized_temp = 1 (warm) -> we want 0.0 -> Q_min
  // So: output = 1 - normalized_temp
  connect(oneConstant.y, invertSignal.u1);
  connect(limiter.y, invertSignal.u2);
  // Scale to Q range and add Q_min
  connect(invertSignal.y, scaleToRange.u1);
  connect(qRangeConstant.y, scaleToRange.u2);
  connect(scaleToRange.y, addQMin.u1);
  connect(oneForQMin.y, addQMin.u2);
  connect(addQMin.y, Q_modulated);
end ModulationController;

