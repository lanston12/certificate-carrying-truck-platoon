function dz = truck_plant_rhs(z,force_command,m,p)
% z=[position; speed; brake pressure; equivalent temperature].
pressure=max(0,min(p.pressure_max,z(3)));
eff=max(0.65,1-0.0015*max(0,z(4)-80));
brake=p.brake_force_max*(pressure/p.pressure_max)*eff;
traction=max(0,force_command);
drag=p.drag_coefficient*z(2)^2;
acc=(traction-brake-drag)/m-9.81*(p.grade+p.rolling_coefficient);
dp=thermal_pneumatic_rhs(z(3:4),force_command,z(2),p);
dz=[z(2);acc;dp];
end
