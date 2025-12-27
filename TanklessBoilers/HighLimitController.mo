within TanklessBoilers;

model HighLimitController "High limit control with anti-short cycle delay"

  import Modelica.Units.SI;

  // Parameters
  parameter SI.Temperature T_max "High limit temperature threshold (K)";
  parameter SI.Time t_anti_short_cycle "Anti-short cycle delay time (s)";
  parameter SI.Temperature threshold_margin = 0.1 
    "Safety margin for threshold comparison (K) - boiler trips at (T_max - margin) to prevent overshoot";

  // Inputs
  Modelica.Blocks.Interfaces.RealInput T_inlet "Inlet water temperature (K)"
    annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));

  // Outputs
  Modelica.Blocks.Interfaces.BooleanOutput highLimitOK 
    "True if boiler can fire (high limit not tripped AND (delay complete OR never tripped))"
    annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));

  Modelica.Blocks.Interfaces.BooleanOutput highLimitTripped 
    "High limit trip status (true when inlet temp >= T_max - threshold_margin)"
    annotation(Placement(transformation(extent = {{100, 30}, {120, 50}})));

  // Internal components
  Modelica.Blocks.Logical.GreaterEqualThreshold highLimitDetector(threshold = T_max - threshold_margin)
    "Detect when inlet temperature exceeds high limit (with safety margin for numerical precision)"
    annotation(Placement(transformation(extent = {{-60, -10}, {-40, 10}})));

  Modelica.Blocks.Logical.Timer antiShortCycleTimer
    "Timer for anti-short cycle delay (starts when high limit tripped, resets when cleared)"
    annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));

  Modelica.Blocks.Logical.GreaterEqualThreshold delayComplete(threshold = t_anti_short_cycle)
    "Check if anti-short cycle delay is complete"
    annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));

  Modelica.Blocks.Logical.Not highLimitNotTripped
    "Invert high limit signal (true when NOT tripped)"
    annotation(Placement(transformation(extent = {{-60, 30}, {-40, 50}})));

  Modelica.Blocks.Logical.And highLimitOK_logic
    "High limit is OK (not tripped AND (delay complete OR never tripped))"
    annotation(Placement(transformation(extent = {{60, -10}, {80, 10}})));
  
  Modelica.Blocks.Logical.Or delayCompleteOrNeverTripped
    "True if delay complete OR high limit never tripped (timer at 0)"
    annotation(Placement(transformation(extent = {{20, 30}, {40, 50}})));
  
  Modelica.Blocks.Logical.LessThreshold timerAtZero(threshold = 0.1)
    "Check if timer is at zero (high limit never tripped or just cleared)"
    annotation(Placement(transformation(extent = {{-20, 30}, {0, 50}})));

equation
  // Detect high limit trip
  connect(T_inlet, highLimitDetector.u)
    annotation(Line(points = {{-120, 0}, {-62, 0}}, color = {0, 0, 127}));

  // Timer starts when high limit is tripped
  connect(highLimitDetector.y, antiShortCycleTimer.u)
    annotation(Line(points = {{-39, 0}, {-22, 0}}, color = {255, 0, 255}));

  // Check if delay is complete
  connect(antiShortCycleTimer.y, delayComplete.u)
    annotation(Line(points = {{1, 0}, {18, 0}}, color = {0, 0, 127}));

  // Invert high limit signal (true when NOT tripped)
  connect(highLimitDetector.y, highLimitNotTripped.u)
    annotation(Line(points = {{-39, 0}, {-50, 0}, {-50, 40}, {-62, 40}}, color = {255, 0, 255}));

  // Check if timer is at zero (meaning high limit never tripped or just cleared)
  connect(antiShortCycleTimer.y, timerAtZero.u)
    annotation(Line(points = {{1, 0}, {10, 0}, {10, 40}, {-22, 40}}, color = {0, 0, 127}));

  // Delay complete OR timer at zero (never tripped)
  connect(delayComplete.y, delayCompleteOrNeverTripped.u1)
    annotation(Line(points = {{41, 0}, {50, 0}, {50, 44}, {18, 44}}, color = {255, 0, 255}));

  connect(timerAtZero.y, delayCompleteOrNeverTripped.u2)
    annotation(Line(points = {{1, 40}, {18, 40}}, color = {255, 0, 255}));

  // High limit is OK if: NOT currently tripped AND (delay complete OR never tripped)
  connect(highLimitNotTripped.y, highLimitOK_logic.u1)
    annotation(Line(points = {{-39, 40}, {40, 40}, {40, 4}, {58, 4}}, color = {255, 0, 255}));

  connect(delayCompleteOrNeverTripped.y, highLimitOK_logic.u2)
    annotation(Line(points = {{41, 40}, {50, 40}, {50, 0}, {58, 0}}, color = {255, 0, 255}));

  // Outputs
  connect(highLimitOK_logic.y, highLimitOK)
    annotation(Line(points = {{81, 0}, {110, 0}}, color = {255, 0, 255}));

  connect(highLimitDetector.y, highLimitTripped)
    annotation(Line(points = {{-39, 0}, {-20, 0}, {-20, 40}, {110, 40}}, color = {255, 0, 255}));

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Text(extent = {{-80, 60}, {80, -60}}, textString = "High Limit\nController", textColor = {0, 0, 0}),
      Polygon(points = {{-60, -40}, {-40, -20}, {-20, -40}, {0, -20}, {20, -40}, {40, -20}, {60, -40}, {60, -60}, {-60, -60}, {-60, -40}}, lineColor = {255, 0, 0}, fillColor = {255, 128, 128}, fillPattern = FillPattern.Solid)}),
    Documentation(info = "<html>
    <p>
    High limit controller with anti-short cycle delay protection.
    </p>
    <p>
    <b>Inputs:</b>
    </p>
    <ul>
    <li><code>T_inlet</code> - Inlet water temperature (K)</li>
    </ul>
    <p>
    <b>Outputs:</b>
    </p>
    <ul>
    <li><code>highLimitOK</code> - True if boiler can fire (high limit not tripped AND (delay complete OR never tripped))</li>
    <li><code>highLimitTripped</code> - True when inlet temperature >= (T_max - threshold_margin)</li>
    </ul>
    <p>
    <b>Operation:</b><br/>
    When the inlet temperature reaches or exceeds (T_max - threshold_margin), the high limit trips 
    and the boiler shuts off. An anti-short cycle timer starts counting. The boiler can fire again 
    only when: (1) the inlet temperature drops below (T_max - threshold_margin) (high limit not tripped), 
    AND (2) the anti-short cycle delay has completed (or high limit was never tripped). The 
    threshold_margin prevents firing at exactly the limit due to numerical precision issues.
    The boiler will NOT fire while the high limit is tripped, regardless of the delay status.
    </p>
    </html>"));
end HighLimitController;

