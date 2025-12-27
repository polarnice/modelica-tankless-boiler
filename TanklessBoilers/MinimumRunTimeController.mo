within TanklessBoilers;

model MinimumRunTimeController "Minimum run time control with high limit override"
  import Modelica.Units.SI;
  // Constants
  constant Real numericalThreshold = 0.1 "Small threshold for numerical comparisons (s)";
  // Parameters
  parameter SI.Time t_min_run = 60 "Minimum run time (s)" annotation(Dialog(group = "Control"));
  // Inputs
  Modelica.Blocks.Interfaces.BooleanInput enable "Enable signal" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
  Modelica.Blocks.Interfaces.BooleanInput highLimitTripped "High limit trip status (can override minimum run time)" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
  // Outputs
  Modelica.Blocks.Interfaces.BooleanOutput minimumRunTimeOK "True if boiler can turn off (minimum run time satisfied OR high limit tripped)" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
  Modelica.Blocks.Interfaces.BooleanOutput mustStayOn "True if boiler must stay on (timer running AND minimum run time not satisfied AND high limit not tripped)" annotation(Placement(transformation(extent = {{100, 20}, {120, 40}})));
  // Internal components
  Modelica.Blocks.Logical.Timer runTimeTimer "Timer for minimum run time (starts when enable goes true)" annotation(Placement(transformation(extent = {{-60, -10}, {-40, 10}})));
  Modelica.Blocks.Logical.GreaterEqualThreshold minTimeComplete(threshold = t_min_run) "Check if minimum run time is complete" annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));
  Modelica.Blocks.Logical.Or minimumRunTimeOK_logic "Minimum run time OK if (time complete OR high limit tripped)" annotation(Placement(transformation(extent = {{40, -10}, {60, 10}})));
  // Must stay on if timer is running AND minimum run time not satisfied AND high limit not tripped
  Modelica.Blocks.Logical.GreaterThreshold timerRunning(threshold = numericalThreshold) "True if timer is running (boiler was firing)" annotation(Placement(transformation(extent = {{-60, 20}, {-40, 40}})));
  Modelica.Blocks.Logical.Not minTimeNotSatisfied "True if minimum run time NOT satisfied" annotation(Placement(transformation(extent = {{-20, 20}, {0, 40}})));
  Modelica.Blocks.Logical.Not highLimitNotTripped "True if high limit NOT tripped" annotation(Placement(transformation(extent = {{-60, 40}, {-40, 60}})));
  Modelica.Blocks.Logical.And mustStayOn_temp "Temp: timer running AND min time not satisfied" annotation(Placement(transformation(extent = {{20, 20}, {40, 40}})));
  Modelica.Blocks.Logical.And mustStayOn_logic "Must stay on if conditions met AND high limit not tripped" annotation(Placement(transformation(extent = {{60, 20}, {80, 40}})));
equation
  // Timer starts when enable is true
  connect(enable, runTimeTimer.u);
  // Check if minimum run time is complete
  connect(runTimeTimer.y, minTimeComplete.u);
  // Minimum run time OK if time complete OR high limit tripped (override)
  connect(minTimeComplete.y, minimumRunTimeOK_logic.u1);
  connect(highLimitTripped, minimumRunTimeOK_logic.u2);
  // Outputs
  connect(minimumRunTimeOK_logic.y, minimumRunTimeOK);
  // Must stay on if timer is running AND minimum run time not satisfied AND high limit not tripped
  connect(runTimeTimer.y, timerRunning.u);
  connect(minTimeComplete.y, minTimeNotSatisfied.u);
  connect(highLimitTripped, highLimitNotTripped.u);
  connect(timerRunning.y, mustStayOn_temp.u1);
  connect(minTimeNotSatisfied.y, mustStayOn_temp.u2);
  connect(mustStayOn_temp.y, mustStayOn_logic.u1);
  connect(highLimitNotTripped.y, mustStayOn_logic.u2);
  connect(mustStayOn_logic.y, mustStayOn);
end MinimumRunTimeController;
