#!/usr/bin/env python3
"""
Plot simulation results from PrimarySecondaryBoilerTest
"""

import matplotlib.pyplot as plt
import numpy as np
import DyMat
import sys
import os

def kelvin_to_fahrenheit(k):
    """Convert Kelvin to Fahrenheit"""
    return (k - 273.15) * 9/5 + 32

def pascal_to_psi(pa):
    """Convert Pascal to PSI"""
    return pa / 6894.76

def watts_to_kbtu(w):
    """Convert Watts to kBTU/h"""
    return w * 3600 / (1000 * 1055.06)

def plot_results(mat_file):
    """Load and plot simulation results"""
    
    # Load the MAT file using DyMat
    print(f"Loading {mat_file}...")
    dm = DyMat.DyMatFile(mat_file)
    
    # List available variables
    print(f"Found {len(dm.names())} variables")
    
    # Extract time vector from any variable's abscissa
    try:
        time, _, _ = dm.abscissa('boiler.Q_actual')
    except Exception:
        # Fallback to Time variable
        try:
            time = dm.abscissa(dm.names()[0])[0]
        except Exception:
            print("Error: Could not extract time vector")
            return
    
    if len(time) == 0:
        print("Error: Time vector is empty")
        return
        
    time_hours = time / 3600  # Convert to hours
    
    # Helper function to safely extract variable
    def get_var(name):
        try:
            return dm.data(name)
        except Exception:
            print(f"Warning: Variable '{name}' not found in results")
            return None
    
    # Extract variables
    boiler_Q = get_var('boiler.Q_actual')
    boiler_Q_modulated = get_var('boiler.Q_modulated_kBTU')
    boiler_modulation_percent = get_var('boiler.modulationPercent')
    boiler_T_inlet = get_var('boiler.T_inlet')
    boiler_T_outlet = get_var('boiler.T_outlet')
    boiler_m_flow = get_var('boiler.m_flow')
    
    # Get setpoint and high limit from boiler (for dynamic plotting)
    boiler_T_setpoint = get_var('boiler.modulationController.T_setpoint')
    boiler_high_limit = get_var('boiler.highLimitController.T_max')
    
    # Baseboard variables (replacing tank)
    baseboard_supply_T = get_var('baseboardSupplyTempSensor.T')
    baseboard_heat_loss = get_var('baseboardHeatLoss.Q_flow')
    baseboard_inlet_T = get_var('baseboardPiping.mediums[1].T')  # First node
    baseboard_outlet_T = get_var('baseboardPiping.mediums[10].T')  # Last node
    room_T = get_var('roomAir.T')  # Room temperature
    
    secondary_pump_m_flow = get_var('secondaryPump.m_flow')
    
    # Create figure with subplots
    fig, axes = plt.subplots(3, 2, figsize=(14, 12))
    from datetime import datetime
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    fig.suptitle('Primary/Secondary Loop Boiler System - Simulation Results', fontsize=16, fontweight='bold')
    # Get setpoint for subtitle
    try:
        T_setpoint = dm.data('boiler.modulationController.T_setpoint')[0]
        T_setpoint_F = (T_setpoint - 273.15) * 9/5 + 32
        fig.text(0.5, 0.96, f'Setpoint: {T_setpoint_F:.0f}°F | Generated: {timestamp}', 
                ha='center', fontsize=10, style='italic', transform=fig.transFigure)
    except:
        fig.text(0.5, 0.96, f'Generated: {timestamp}', 
                ha='center', fontsize=10, style='italic', transform=fig.transFigure)
    
    # Plot 1: Boiler Heat Output (showing actual output)
    ax = axes[0, 0]
    if boiler_Q is not None:
        # Plot the actual heat output (what the boiler is actually producing)
        ax.plot(time_hours, watts_to_kbtu(boiler_Q), 'b-', linewidth=2, label='Actual Output (kBTU/h)')
        ax.set_ylabel('Heat Output (kBTU/h)', fontsize=10, color='b')
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Boiler Heat Output (Actual)', fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.set_ylim(bottom=0)
        ax.tick_params(axis='y', labelcolor='b')
        
        # Add Q_min and Q_max reference lines
        try:
            q_min = dm.data('boiler.modulationController.Q_min')[0]
            q_max = dm.data('boiler.modulationController.Q_max')[0]
            ax.axhline(y=watts_to_kbtu(q_min), color='g', linestyle='--', alpha=0.5, label=f'Q_min ({watts_to_kbtu(q_min):.0f} kBTU/h)')
            ax.axhline(y=watts_to_kbtu(q_max), color='r', linestyle='--', alpha=0.5, label=f'Q_max ({watts_to_kbtu(q_max):.0f} kBTU/h)')
        except:
            pass
        
        # Add desired output (modulated) as a reference line
        if boiler_Q_modulated is not None:
            ax.plot(time_hours, boiler_Q_modulated, 'orange', linewidth=1, linestyle=':', label='Desired Output', alpha=0.6)
        
        # Add modulation percentage as second y-axis
        if boiler_modulation_percent is not None:
            ax2 = ax.twinx()
            ax2.plot(time_hours, boiler_modulation_percent, 'purple', linewidth=1.5, linestyle='--', label='Modulation %', alpha=0.7)
            ax2.set_ylabel('Modulation (%)', fontsize=10, color='purple')
            ax2.set_ylim(0, 100)
            ax2.tick_params(axis='y', labelcolor='purple')
            # Combine legends
            lines1, labels1 = ax.get_legend_handles_labels()
            lines2, labels2 = ax2.get_legend_handles_labels()
            ax.legend(lines1 + lines2, labels1 + labels2, loc='best', fontsize=7)
        else:
            ax.legend(loc='best', fontsize=8)
    
    # Plot 2: Boiler Temperatures
    ax = axes[0, 1]
    if boiler_T_inlet is not None and boiler_T_outlet is not None:
        ax.plot(time_hours, kelvin_to_fahrenheit(boiler_T_inlet), 'b-', linewidth=2, label='Inlet')
        ax.plot(time_hours, kelvin_to_fahrenheit(boiler_T_outlet), 'r-', linewidth=2, label='Outlet')
        # Dynamic setpoint and high limit lines
        if boiler_T_setpoint is not None:
            T_setpoint_F = kelvin_to_fahrenheit(boiler_T_setpoint[0])
            ax.axhline(y=T_setpoint_F, color='g', linestyle='--', alpha=0.5, label=f'Setpoint ({T_setpoint_F:.0f}°F)')
        if boiler_high_limit is not None:
            T_high_limit_F = kelvin_to_fahrenheit(boiler_high_limit[0])
            ax.axhline(y=T_high_limit_F, color='orange', linestyle='--', alpha=0.5, label=f'High Limit ({T_high_limit_F:.0f}°F)')
        ax.set_ylabel('Temperature (°F)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Boiler Temperatures', fontweight='bold')
        ax.legend(loc='best', fontsize=8)
        ax.grid(True, alpha=0.3)
    
    # Plot 3: Combined Flow Rates (Primary and Secondary) with Pump Speeds on right axis
    ax = axes[1, 0]
    if boiler_m_flow is not None or secondary_pump_m_flow is not None:
        if boiler_m_flow is not None:
            primary_gpm = boiler_m_flow * 15.85
            ax.plot(time_hours, primary_gpm, 'purple', linewidth=2, label='Primary Loop')
        if secondary_pump_m_flow is not None:
            secondary_gpm = secondary_pump_m_flow * 15.85
            ax.plot(time_hours, secondary_gpm, 'green', linewidth=2, label='Secondary Loop')
        ax.set_ylabel('Flow Rate (GPM)', fontsize=10, color='purple')
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Flow Rates & Pump Speeds', fontweight='bold')
        ax.tick_params(axis='y', labelcolor='purple')
        ax.grid(True, alpha=0.3)
        # Set y-axis to 20% above max for better visibility
        max_gpm = max(np.max(primary_gpm) if boiler_m_flow is not None else 0, 
                     np.max(secondary_gpm) if secondary_pump_m_flow is not None else 0)
        ax.set_ylim(bottom=0, top=max_gpm * 1.2 if max_gpm > 0 else 10)
        
        # Add pump speeds on right y-axis
        try:
            primary_pump_speed = dm.data('boiler.primaryPump.N')
            secondary_pump_speed = dm.data('secondaryPump.N')
            ax2 = ax.twinx()
            ax2.plot(time_hours, primary_pump_speed, 'purple', linewidth=1.5, linestyle='--', label='Primary Pump', alpha=0.7)
            ax2.plot(time_hours, secondary_pump_speed, 'green', linewidth=1.5, linestyle='--', label='Secondary Pump', alpha=0.7)
            ax2.set_ylabel('Pump Speed (RPM)', fontsize=10, color='green')
            ax2.tick_params(axis='y', labelcolor='green')
            max_speed = max(np.max(primary_pump_speed), np.max(secondary_pump_speed))
            ax2.set_ylim(bottom=0, top=max_speed * 1.2 if max_speed > 0 else 1000)
            # Combine legends
            lines1, labels1 = ax.get_legend_handles_labels()
            lines2, labels2 = ax2.get_legend_handles_labels()
            ax.legend(lines1 + lines2, labels1 + labels2, loc='best', fontsize=7)
        except Exception:
            ax.legend(loc='best', fontsize=8)
    
    # Plot 4: Baseboard Heat Loss
    ax = axes[1, 1]
    if baseboard_heat_loss is not None:
        # Heat loss is positive (heat flowing from baseboard to house)
        baseboard_heat_loss_kBTU_h = baseboard_heat_loss * 3600 / (1000 * 1055.06)
        ax.plot(time_hours, baseboard_heat_loss_kBTU_h, 'red', linewidth=2, label='Heat to House')
        ax.set_ylabel('Heat Loss (kBTU/h)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Baseboard Heat Loss to House', fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.set_ylim(bottom=0)
        ax.legend(loc='best', fontsize=8)
    else:
        ax.text(0.5, 0.5, 'Baseboard heat loss data not available', 
                ha='center', va='center', transform=ax.transAxes)
    
    # Plot 5: Baseboard & Room Temperatures
    ax = axes[2, 0]
    if baseboard_inlet_T is not None and baseboard_outlet_T is not None:
        ax.plot(time_hours, kelvin_to_fahrenheit(baseboard_inlet_T), 'red', linewidth=2, label='Baseboard Inlet')
        ax.plot(time_hours, kelvin_to_fahrenheit(baseboard_outlet_T), 'blue', linewidth=2, label='Baseboard Outlet')
        if room_T is not None:
            ax.plot(time_hours, kelvin_to_fahrenheit(room_T), 'green', linewidth=2, label='Room Temp')
        ax.set_ylabel('Temperature (°F)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Baseboard & Room Temperatures', fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.legend(loc='best', fontsize=8)
    elif baseboard_supply_T is not None:
        ax.plot(time_hours, kelvin_to_fahrenheit(baseboard_supply_T), 'darkblue', linewidth=2, label='Baseboard Supply')
        if room_T is not None:
            ax.plot(time_hours, kelvin_to_fahrenheit(room_T), 'green', linewidth=2, label='Room Temp')
        ax.set_ylabel('Temperature (°F)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Baseboard & Room Temperatures', fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.legend(loc='best', fontsize=8)
    
    # Plot 6: (available for future use)
    ax = axes[2, 1]
    ax.axis('off')  # Hide this subplot for now
    
    plt.tight_layout()
    
    # Save figure
    output_file = mat_file.replace('.mat', '_plots.png')
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    print(f"Plots saved to: {output_file}")
    
    # Show figure
    plt.show()
    
    # Print summary statistics
    print("\n" + "="*60)
    print("SIMULATION SUMMARY")
    print("="*60)
    print(f"Simulation time: {time[-1]/3600:.2f} hours ({time[-1]:.0f} seconds)")
    
    if boiler_Q is not None:
        avg_heat = watts_to_kbtu(np.mean(boiler_Q))
        max_heat = watts_to_kbtu(np.max(boiler_Q))
        print("\nBoiler Heat Output:")
        print(f"  Average: {avg_heat:.1f} kBTU/h")
        print(f"  Maximum: {max_heat:.1f} kBTU/h")
    
    if boiler_T_inlet is not None and boiler_T_outlet is not None:
        avg_inlet = kelvin_to_fahrenheit(np.mean(boiler_T_inlet))
        avg_outlet = kelvin_to_fahrenheit(np.mean(boiler_T_outlet))
        print("\nBoiler Temperatures:")
        print(f"  Average Inlet:  {avg_inlet:.1f}°F")
        print(f"  Average Outlet: {avg_outlet:.1f}°F")
        print(f"  Average ΔT:     {avg_outlet - avg_inlet:.1f}°F")
    
    if baseboard_inlet_T is not None and baseboard_outlet_T is not None:
        avg_inlet = kelvin_to_fahrenheit(np.mean(baseboard_inlet_T))
        avg_outlet = kelvin_to_fahrenheit(np.mean(baseboard_outlet_T))
        print("\nBaseboard Temperatures:")
        print(f"  Average Inlet:  {avg_inlet:.1f}°F")
        print(f"  Average Outlet: {avg_outlet:.1f}°F")
        print(f"  Average ΔT:     {avg_inlet - avg_outlet:.1f}°F")
    elif baseboard_supply_T is not None:
        avg_baseboard = kelvin_to_fahrenheit(np.mean(baseboard_supply_T))
        final_baseboard = kelvin_to_fahrenheit(baseboard_supply_T[-1])
        print("\nBaseboard Supply:")
        print(f"  Average Temperature: {avg_baseboard:.1f}°F")
        print(f"  Final Temperature:   {final_baseboard:.1f}°F")
    
    if baseboard_heat_loss is not None:
        # Heat loss is positive (heat flowing to room)
        avg_heat_loss = np.mean(baseboard_heat_loss) * 3600 / (1000 * 1055.06)
        print(f"\nBaseboard Heat to Room:")
        print(f"  Average: {avg_heat_loss:.1f} kBTU/h")
    
    if room_T is not None:
        room_T_F_start = kelvin_to_fahrenheit(room_T[0])
        room_T_F_end = kelvin_to_fahrenheit(room_T[-1])
        print(f"\nRoom Temperature:")
        print(f"  Start: {room_T_F_start:.1f}°F")
        print(f"  End:   {room_T_F_end:.1f}°F")
        print(f"  Rise:  {room_T_F_end - room_T_F_start:.1f}°F")
    
    if boiler_m_flow is not None:
        avg_primary = boiler_m_flow.mean() * 15.85
        print("\nFlow Rates:")
        print(f"  Primary Loop:   {avg_primary:.2f} GPM")
    
    if secondary_pump_m_flow is not None:
        avg_secondary = secondary_pump_m_flow.mean() * 15.85
        print(f"  Secondary Loop: {avg_secondary:.2f} GPM")
    
    print("="*60)

if __name__ == '__main__':
    # Default file
    mat_file = 'TanklessBoilers.Examples.PrimarySecondaryBoilerTest_res.mat'
    
    # Check if file was provided as argument
    if len(sys.argv) > 1:
        mat_file = sys.argv[1]
    
    # Check if file exists
    if not os.path.exists(mat_file):
        print(f"Error: File '{mat_file}' not found!")
        print(f"Usage: {sys.argv[0]} [path/to/results.mat]")
        sys.exit(1)
    
    # Plot results
    plot_results(mat_file)

