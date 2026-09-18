function [ok,margins,q] = command_guards(q_desired,q_previous,dt,p)
% Saturation is logged but does not count as certified normal authority.
amp=p.accel_virtual_limit-abs(q_desired);
slew=p.accel_virtual_slew-abs(q_desired-q_previous)/dt;
ok=amp>=0.01 && slew>=0.01;
q=max(-p.accel_virtual_limit,min(p.accel_virtual_limit,q_desired));
q=max(q_previous-p.accel_virtual_slew*dt,min(q_previous+p.accel_virtual_slew*dt,q));
margins=[amp,slew];
end
