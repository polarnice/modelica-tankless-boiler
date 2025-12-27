within TanklessBoilers;

model SetpointController "Setpoint control with hysteresis to prevent rapid cycling"

  import Modelica.Units.SI;

  // Parameters
  parameter SI.Temperature T_setpoint "Temperature setpoint (K)";
  parameter SI.Temperature deadband "Hysteresis deadband (K) - total width (on/off spread)";

  // Inputs
  Modelica.Blocks.Interfaces.RealInput T_inlet "Inlet water temperature (K)"
    annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));

  // Outputs
  Modelica.Blocks.Interfaces.BooleanOutput setpointOK
    "True if boiler should fire (temperature below setpoint + deadband/2)"
    annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));

  // Internal components - use Modelica.Blocks.Logical.Hysteresis for setpoint control
  // Standard hysteresis: false when u < uLow, true when u > uHigh (requires uHigh > uLow)
  // We want: true (need heat) when T < (setpoint - deadband/2), false (enough heat) when T > (setpoint + deadband/2)
  // Set: uLow = setpoint - deadband/2, uHigh = setpoint + deadband/2 (normal order)
  // This gives: false when T < (setpoint - deadband/2), true when T > (setpoint + deadband/2)
  // Then invert the output to get the desired behavior
  Modelica.Blocks.Logical.Hysteresis hysteresis(
    uLow = T_setpoint - deadband/2,
    uHigh = T_setpoint + deadband/2)
    "Hysteresis: false when T < (setpoint - deadband/2), true when T > (setpoint + deadband/2)"
    annotation(Placement(transformation(extent = {{-20, -10}, {0, 10}})));

  Modelica.Blocks.Logical.Not invertOutput
    "Invert hysteresis output: true when T below setpoint (need heat)"
    annotation(Placement(transformation(extent = {{20, -10}, {40, 10}})));

equation
  // Connect inlet temperature to hysteresis input
  connect(T_inlet, hysteresis.u)
    annotation(Line(points = {{-120, 0}, {-22, 0}}, color = {0, 0, 127}));

  // Invert output: true when temperature is below setpoint (should fire)
  connect(hysteresis.y, invertOutput.u)
    annotation(Line(points = {{1, 0}, {18, 0}}, color = {255, 0, 255}));

  connect(invertOutput.y, setpointOK)
    annotation(Line(points = {{41, 0}, {110, 0}}, color = {255, 0, 255}));

  annotation(
    Icon(graphics = {
      Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid),
      Text(extent = {{-80, 60}, {80, -60}}, textString = "Setpoint\nController", textColor = {0, 0, 0}),
      Line(points = {{-60, -40}, {-40, -20}, {-20, 0}, {0, 20}, {20, 40}, {40, 60}}, color = {255, 0, 0})}),
    Documentation(info = "<html>
    <p>
    Setpoint controller with hysteresis to prevent rapid cycling of the boiler.
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
    <li><code>setpointOK</code> - True when temperature is below setpoint (boiler should fire)</li>
    </ul>
    <p>
    <b>Operation:</b><br/>
    The controller uses hysteresis to prevent rapid cycling:
    </p>
    <ul>
    <li>Boiler turns <b>ON</b> when T_inlet &lt; (T_setpoint - deadband/2)</li>
    <li>Boiler turns <b>OFF</b> when T_inlet &gt; (T_setpoint + deadband/2)</li>
    </ul>
    <p>
    The deadband creates a temperature range where the boiler state remains unchanged,
    preventing rapid on/off cycling when temperature hovers near the setpoint.
    </p>
    </html>"));
end SetpointController;

