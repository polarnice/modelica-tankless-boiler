within TanklessBoilers;

model MinimumRunTimeController "Minimum run time control with high limit override"

  import Modelica.Units.SI;

  // Parameters
  parameter SI.Time t_min_run "Minimum run time (s)";

  // Inputs
  Modelica.Blocks.Interfaces.BooleanInput enable "Enable signal"
    annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));

  Modelica.Blocks.Interfaces.BooleanInput highLimitTripped "High limit trip status (can override minimum run time)"
    annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));

  // Outputs
  Modelica.Blocks.Interfaces.BooleanOutput minimumRunTimeOK
    "True if boiler can turn off (minimum run time satisfied OR high limit tripped)"
    annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));

  Modelica.Blocks.Interfaces.BooleanOutput mustStayOn
    "True if boiler must stay on (timer running AND minimum run time not satisfied AND high limit not tripped)"
    annotation(Placement(transformation(extent = {{100, 20}, {120, 40}})));

  // Internal components
  Modelica.Blocks.Logical.Timer runTimeTimer
    "Timer for minimum run time (starts when enable goes true)"
    annotation(Placement(transformation(extent = {{-60, -10}, {-40, 10}})));

  Modelica.Blocks.Logical.GreaterEqualThreshold minTimeComplete(threshold = t_min_run)
    "Check if minimum run time is complete"
    annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));

  Modelica.Blocks.Logical.Or minimumRunTimeOK_logic
    "Minimum run time OK if (time complete OR high limit tripped)"
    annotation(Placement(transformation(extent = {{40, -10}, {60, 10}})));

  // Must stay on if timer is running AND minimum run time not satisfied AND high limit not tripped
  Modelica.Blocks.Logical.GreaterThreshold timerRunning(threshold = 0.1)
    "True if timer is running (boiler was firing)"
    annotation(Placement(transformation(extent = {{-60, 20}, {-40, 40}})));

  Modelica.Blocks.Logical.Not minTimeNotSatisfied
    "True if minimum run time NOT satisfied"
    annotation(Placement(transformation(extent = {{-20, 20}, {0, 40}})));

  Modelica.Blocks.Logical.Not highLimitNotTripped
    "True if high limit NOT tripped"
    annotation(Placement(transformation(extent = {{-60, 40}, {-40, 60}})));

  Modelica.Blocks.Logical.And mustStayOn_temp
    "Temp: timer running AND min time not satisfied"
    annotation(Placement(transformation(extent = {{20, 20}, {40, 40}})));

  Modelica.Blocks.Logical.And mustStayOn_logic
    "Must stay on if conditions met AND high limit not tripped"
    annotation(Placement(transformation(extent = {{60, 20}, {80, 40}})));

equation
  // Timer starts when enable is true
  connect(enable, runTimeTimer.u)
    annotation(Line(points = {{-120, 0}, {-62, 0}}, color = {255, 0, 255}));

  // Check if minimum run time is complete
  connect(runTimeTimer.y, minTimeComplete.u)
    annotation(Line(points = {{-39, 0}, {-22, 0}}, color = {0, 0, 127}));

  // Minimum run time OK if time complete OR high limit tripped (override)
  connect(minTimeComplete.y, minimumRunTimeOK_logic.u1)
    annotation(Line(points = {{1, 0}, {38, 0}}, color = {255, 0, 255}));

  connect(highLimitTripped, minimumRunTimeOK_logic.u2)
    annotation(Line(points = {{-120, -40}, {-80, -40}, {-80, -8}, {38, -8}}, color = {255, 0, 255}));

  // Outputs
  connect(minimumRunTimeOK_logic.y, minimumRunTimeOK)
    annotation(Line(points = {{61, 0}, {110, 0}}, color = {255, 0, 255}));

  // Must stay on if timer is running AND minimum run time not satisfied AND high limit not tripped
  connect(runTimeTimer.y, timerRunning.u)
    annotation(Line(points = {{-39, 0}, {-50, 0}, {-50, 30}, {-62, 30}}, color = {0, 0, 127}));

  connect(minTimeComplete.y, minTimeNotSatisfied.u)
    annotation(Line(points = {{1, 0}, {10, 0}, {10, 30}, {-22, 30}}, color = {255, 0, 255}));

  connect(highLimitTripped, highLimitNotTripped.u)
    annotation(Line(points = {{-120, -40}, {-70, -40}, {-70, 50}, {-62, 50}}, color = {255, 0, 255}));

  connect(timerRunning.y, mustStayOn_temp.u1)
    annotation(Line(points = {{-39, 30}, {18, 30}}, color = {255, 0, 255}));

  connect(minTimeNotSatisfied.y, mustStayOn_temp.u2)
    annotation(Line(points = {{1, 30}, {18, 30}}, color = {255, 0, 255}));

  connect(mustStayOn_temp.y, mustStayOn_logic.u1)
    annotation(Line(points = {{41, 30}, {58, 30}}, color = {255, 0, 255}));

  connect(highLimitNotTripped.y, mustStayOn_logic.u2)
    annotation(Line(points = {{-39, 50}, {50, 50}, {50, 26}, {58, 26}}, color = {255, 0, 255}));

  connect(mustStayOn_logic.y, mustStayOn)
    annotation(Line(points = {{81, 30}, {110, 30}}, color = {255, 0, 255}));

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Text(extent = {{-80, 60}, {80, -60}}, textString = "Min Run\nTime", textColor = {0, 0, 0}),
      Text(extent = {{-80, -60}, {80, -80}}, textString = "Controller", textColor = {0, 0, 0})}),
    Documentation(info = "<html>
    <p>
    Minimum run time controller that prevents the boiler from cycling too frequently.
    </p>
    <p>
    <b>Inputs:</b>
    </p>
    <ul>
    <li><code>enable</code> - Enable signal (starts timer when true)</li>
    <li><code>highLimitTripped</code> - High limit trip status (can override minimum run time)</li>
    </ul>
    <p>
    <b>Outputs:</b>
    </p>
    <ul>
    <li><code>minimumRunTimeOK</code> - True if boiler can turn off (minimum run time satisfied OR high limit tripped)</li>
    </ul>
    <p>
    <b>Operation:</b><br/>
    When the enable signal goes true, a timer starts. The boiler must run for at least t_min_run seconds
    before it can turn off normally. However, if the high limit trips, the boiler can shut off immediately
    (high limit overrides minimum run time).
    </p>
    </html>"));
end MinimumRunTimeController;

