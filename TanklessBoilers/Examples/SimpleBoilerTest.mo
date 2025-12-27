within TanklessBoilers.Examples;

model SimpleBoilerTest "Simple test of TanklessBoiler model with secondary loop"
  extends Modelica.Icons.Example;

  import TanklessBoilers.*;
  import Modelica.Units.SI;

  // Fluid medium
  package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater;

  // System properties
  inner Modelica.Fluid.System system(energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial,
    p_ambient = 101325, T_ambient = 273.15 + 20)
    "System properties";

  // Tankless boiler (includes internal closed primary loop)
  TanklessBoiler boiler(
    Q_max_kBTU = 120,
    T_setpoint_F = 150,
    highLimit_F = 180,
    m_flow_GPM = 5.0,
    primaryLoopVolume_gal = 2.0,
    redeclare package Medium = Medium)
    "Tankless boiler with internal closed primary loop";

  // No secondary loop components - testing boiler primary loop only

  // Control signal - simple constant enable
  Modelica.Blocks.Sources.BooleanConstant enableSignal(k = true)
    "Boiler enable signal (always on for testing)";

equation
  // Boiler is a closed primary loop - no external connections needed
  // Primary loop (inside boiler): primaryLoopVolume.ports[1] → pump → heater → primaryLoopVolume.ports[2]
  
  // Connect control signal
  connect(enableSignal.y, boiler.enable)
    annotation(Line(points = {{-80, 0}, {-40, 0}, {-40, 40}, {-20, 40}}, color = {255, 0, 255}));

  annotation(
    experiment(StartTime = 0, StopTime = 1500, Tolerance = 1e-6, Interval = 1),
    Documentation(info = "<html>
    <p>
    Simple test model for the TanklessBoiler component.
    </p>
    <p>
    This example demonstrates the TanklessBoiler model with its internal closed primary loop 
    (no secondary loop connections). The boiler includes its own internal primary loop with 
    a pump that runs when enabled. The primary loop volume is configurable (defaults to 2 gallons).
    </p>
    <p>
    This model tests the boiler with:
    </p>
    <ul>
    <li>Internal closed primary loop (2 gallons, baked into boiler model)</li>
    <li>Initial water temperature of 60°F</li>
    <li>On/off control schedule (enables at 100s, 500s, 900s, off at 1300s)</li>
    <li>No secondary loop connections (ports left unconnected)</li>
    </ul>
    <p>
    Note: In a real system, the secondary (distribution) loop would connect to the external 
    ports (<code>port_a</code> and <code>port_b</code>) at the closely spaced tees, allowing 
    water to be drawn from and returned to the primary loop. This test model omits the secondary 
    loop to test just the primary loop and boiler operation.
    </p>
    <p>
    To generate plots from simulation results, use the included 
    <code>plot_simple_boiler.py</code> script.
    </p>
    </html>"));
end SimpleBoilerTest;

