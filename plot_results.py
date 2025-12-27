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
    boiler_T_inlet = get_var('boiler.T_inlet')
    boiler_T_outlet = get_var('boiler.T_outlet')
    boiler_m_flow = get_var('boiler.m_flow')
    
    tank_T = get_var('storageTank.medium.T')
    
    secondary_pump_m_flow = get_var('secondaryPump.m_flow')
    
    # Create figure with subplots
    fig, axes = plt.subplots(3, 2, figsize=(14, 10))
    fig.suptitle('Primary/Secondary Loop Boiler System - Simulation Results', fontsize=16, fontweight='bold')
    
    # Plot 1: Boiler Heat Output
    ax = axes[0, 0]
    if boiler_Q is not None:
        ax.plot(time_hours, watts_to_kbtu(boiler_Q), 'r-', linewidth=2)
        ax.set_ylabel('Heat Output (kBTU/h)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Boiler Heat Output', fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.set_ylim(bottom=0)
    
    # Plot 2: Boiler Temperatures
    ax = axes[0, 1]
    if boiler_T_inlet is not None and boiler_T_outlet is not None:
        ax.plot(time_hours, kelvin_to_fahrenheit(boiler_T_inlet), 'b-', linewidth=2, label='Inlet')
        ax.plot(time_hours, kelvin_to_fahrenheit(boiler_T_outlet), 'r-', linewidth=2, label='Outlet')
        ax.axhline(y=170, color='g', linestyle='--', alpha=0.5, label='Setpoint (170°F)')
        ax.axhline(y=180, color='orange', linestyle='--', alpha=0.5, label='High Limit (180°F)')
        ax.set_ylabel('Temperature (°F)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Boiler Temperatures', fontweight='bold')
        ax.legend(loc='best', fontsize=8)
        ax.grid(True, alpha=0.3)
    
    # Plot 3: Primary Loop Flow Rate
    ax = axes[1, 0]
    if boiler_m_flow is not None:
        # Convert kg/s to GPM (1 kg/s ≈ 15.85 GPM for water)
        gpm = boiler_m_flow * 15.85
        ax.plot(time_hours, gpm, 'purple', linewidth=2)
        ax.set_ylabel('Flow Rate (GPM)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Primary Loop Flow Rate', fontweight='bold')
        ax.grid(True, alpha=0.3)
        # Set y-axis to 20% above max for better visibility
        ax.set_ylim(bottom=0, top=np.max(gpm) * 1.2)
    
    # Plot 4: Secondary Loop Flow Rate
    ax = axes[1, 1]
    if secondary_pump_m_flow is not None:
        gpm = secondary_pump_m_flow * 15.85
        ax.plot(time_hours, gpm, 'green', linewidth=2)
        ax.set_ylabel('Flow Rate (GPM)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Secondary Loop Flow Rate', fontweight='bold')
        ax.grid(True, alpha=0.3)
        # Set y-axis to 20% above max for better visibility
        ax.set_ylim(bottom=0, top=np.max(gpm) * 1.2)
    
    # Plot 5: Storage Tank Temperature
    ax = axes[2, 0]
    if tank_T is not None:
        ax.plot(time_hours, kelvin_to_fahrenheit(tank_T), 'darkblue', linewidth=2)
        ax.set_ylabel('Temperature (°F)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Storage Tank Temperature', fontweight='bold')
        ax.grid(True, alpha=0.3)
    
    # Plot 6: Both Pump Speeds
    ax = axes[2, 1]
    try:
        primary_pump_speed = dm.data('boiler.primaryPump.N')
        secondary_pump_speed = dm.data('secondaryPump.N')
        ax.plot(time_hours, primary_pump_speed, 'purple', linewidth=2, label='Primary Pump')
        ax.plot(time_hours, secondary_pump_speed, 'darkgreen', linewidth=2, label='Secondary Pump')
        ax.set_ylabel('Speed (RPM)', fontsize=10)
        ax.set_xlabel('Time (hours)', fontsize=10)
        ax.set_title('Pump Speeds', fontweight='bold')
        ax.legend(loc='best', fontsize=8)
        ax.grid(True, alpha=0.3)
        max_speed = max(np.max(primary_pump_speed), np.max(secondary_pump_speed))
        ax.set_ylim(bottom=0, top=max_speed * 1.2 if max_speed > 0 else 2000)
    except Exception as e:
        ax.text(0.5, 0.5, f'Pump speed data not available\n{str(e)}', 
                ha='center', va='center', transform=ax.transAxes)
    
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
    
    if tank_T is not None:
        avg_tank = kelvin_to_fahrenheit(np.mean(tank_T))
        final_tank = kelvin_to_fahrenheit(tank_T[-1])
        print("\nStorage Tank:")
        print(f"  Average Temperature: {avg_tank:.1f}°F")
        print(f"  Final Temperature:   {final_tank:.1f}°F")
    
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

