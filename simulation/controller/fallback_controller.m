function q = fallback_controller(e,r,p,q_previous,dt)
% Local radar and own applied-command history only; no V2V input.
q=max(-p.accel_virtual_limit,min(p.accel_virtual_limit, ...
    p.fallback_ke*e+p.fallback_kr*r));
q=max(q_previous-p.accel_virtual_slew*dt, ...
    min(q_previous+p.accel_virtual_slew*dt,q));
end
