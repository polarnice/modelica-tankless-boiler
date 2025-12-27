within TanklessBoilers;

model HighLimitController "High limit control with anti-short cycle delay"
  import Modelica.Units.SI;
  // Constants
  constant Real numericalThreshold = 0.1 "Small threshold for numerical comparisons (K or s)";
  constant Real kelvinOffset = 273.15 "Kelvin temperature offset";
  constant Real defaultHighLimitF = 180.0 "Default high limit in Fahrenheit";
  constant Real defaultAntiShortCycleMin = 5.0 "Default anti-short cycle delay in minutes";
  // Parameters
  parameter SI.Temperature T_max = kelvinOffset + defaultHighLimitF "High limit temperature threshold (K)" annotation(Dialog(group = "Control"));
  parameter SI.Time t_anti_short_cycle = defaultAntiShortCycleMin * 60 "Anti-short cycle delay time (s)" annotation(Dialog(group = "Control"));
  parameter SI.Temperature threshold_margin = numericalThreshold "Safety margin for threshold comparison (K) - boiler trips at (T_max - margin) to prevent overshoot" annotation(Dialog(group = "Control"));
  // Inputs
  Modelica.Blocks.Interfaces.RealInput T_inlet "Inlet water temperature (K)" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
  // Outputs
  Modelica.Blocks.Interfaces.BooleanOutput highLimitOK "True if boiler can fire (high limit not tripped AND (delay complete OR never tripped))" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
  Modelica.Blocks.Interfaces.BooleanOutput highLimitTripped "High limit trip status (true when inlet temp >= T_max - threshold_margin)" annotation(Placement(transformation(extent = {{100, 30}, {120, 50}})));
  // Internal components
  Modelica.Blocks.Logical.GreaterEqualThreshold highLimitDetector(threshold = T_max - threshold_margin) "Detect when inlet temperature exceeds high limit (with safety margin for numerical precision)" annotation(Placement(transformation(extent = {{-60, -10}, {-40, 10}})));
  Modelica.Blocks.Logical.Timer antiShortCycleTimer "Timer for anti-short cycle delay (starts when high limit tripped, resets when cleared)" annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));
  Modelica.Blocks.Logical.GreaterEqualThreshold delayComplete(threshold = t_anti_short_cycle) "Check if anti-short cycle delay is complete" annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));
  Modelica.Blocks.Logical.Not highLimitNotTripped "Invert high limit signal (true when NOT tripped)" annotation(Placement(transformation(extent = {{-60, 30}, {-40, 50}})));
  Modelica.Blocks.Logical.And highLimitOK_logic "High limit is OK (not tripped AND (delay complete OR never tripped))" annotation(Placement(transformation(extent = {{60, -10}, {80, 10}})));
  Modelica.Blocks.Logical.Or delayCompleteOrNeverTripped "True if delay complete OR high limit never tripped (timer at 0)" annotation(Placement(transformation(extent = {{20, 30}, {40, 50}})));
  Modelica.Blocks.Logical.LessThreshold timerAtZero(threshold = numericalThreshold) "Check if timer is at zero (high limit never tripped or just cleared)" annotation(Placement(transformation(extent = {{-20, 30}, {0, 50}})));
equation
  // Detect high limit trip
  connect(T_inlet, highLimitDetector.u);
  // Timer starts when high limit is tripped
  connect(highLimitDetector.y, antiShortCycleTimer.u);
  // Check if delay is complete
  connect(antiShortCycleTimer.y, delayComplete.u);
  // Invert high limit signal (true when NOT tripped)
  connect(highLimitDetector.y, highLimitNotTripped.u);
  // Check if timer is at zero (meaning high limit never tripped or just cleared)
  connect(antiShortCycleTimer.y, timerAtZero.u);
  // Delay complete OR timer at zero (never tripped)
  connect(delayComplete.y, delayCompleteOrNeverTripped.u1);
  connect(timerAtZero.y, delayCompleteOrNeverTripped.u2);
  // High limit is OK if: NOT currently tripped AND (delay complete OR never tripped)
  connect(highLimitNotTripped.y, highLimitOK_logic.u1);
  connect(delayCompleteOrNeverTripped.y, highLimitOK_logic.u2);
  // Outputs
  connect(highLimitOK_logic.y, highLimitOK);
  connect(highLimitDetector.y, highLimitTripped);
end HighLimitController;
