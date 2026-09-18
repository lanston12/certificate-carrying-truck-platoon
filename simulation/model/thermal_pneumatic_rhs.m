function dz = thermal_pneumatic_rhs(z,force_command,v,p)
% z=[brake pressure (Pa); equivalent brake temperature (C)].
target=p.pressure_max*min(1,max(0,-force_command)/p.brake_force_max);
if target>z(1), tau=p.pressure_time_charge; else, tau=p.pressure_time_exhaust; end
eff=1-0.0015*max(0,z(2)-80);
brake_force=p.brake_force_max*max(0,min(1,z(1)/p.pressure_max))*eff;
dz=[(target-z(1))/tau; ...
    (p.brake_heat_fraction*brake_force*max(v,0)-p.thermal_conductance*(z(2)-p.ambient_C))/p.thermal_capacity];
end
