within ;

package TanklessBoilers "Library of tankless boiler models for Modelica"
  extends Modelica.Icons.Package;

  annotation(
    uses(Modelica(version = "4.0.0")),
    version = "1.0.0",
    Documentation(info = "<html>
    <p>
    This package contains reusable tankless boiler models for hydronic heating systems.
    </p>
    <h4>Main Models</h4>
          <ul>
          <li><b>TanklessBoiler</b> - A configurable tankless boiler with control inputs and outputs</li>
          <li><b>SetpointController</b> - Setpoint control with hysteresis to prevent rapid cycling</li>
          <li><b>HighLimitController</b> - High limit control with anti-short cycle delay protection</li>
          <li><b>MinimumRunTimeController</b> - Minimum run time control with high limit override</li>
          </ul>
          <h4>Examples</h4>
          <p>
          See <a href=\"modelica://TanklessBoilers.Examples\">TanklessBoilers.Examples</a> for usage examples.
          </p>
          <ul>
          <li><b>SimpleBoilerTest</b> - Standalone boiler test without secondary loop</li>
          <li><b>SimpleExample</b> - Basic usage example</li>
          </ul>
    </html>"));
end TanklessBoilers;

