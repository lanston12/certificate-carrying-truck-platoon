function g=segment_command_guard(L0,L1,X0,X1,vertices,dt,cell,art,mass,p,q_previous)
% Exact extrema of the planned FOH gain/regressor product on [0,dt].
% Both regressor endpoints must already be available from delayed history.
K0=L0*vertices; dK=(L1-L0)*vertices;
dX=X1-X0;
c0=K0*X0'; c1=K0*dX'+dK*X0'; c2=dK*dX';
values=[c0,c0+c1+c2];
if abs(c2)>eps
    stationary=-c1/(2*c2);
    if stationary>0 && stationary<1
        values(end+1)=c0+c1*stationary+c2*stationary^2;
    end
end
g.q_seg_max=max(abs(values));
g.qdot_seg_max=max(abs([c1,c1+2*c2]))/dt;
g.q_start=c0;
g.q_end=c0+c1+c2;
rho_min=art.cell_bounds.rho_factor(1)/mass;
nu_max=art.cell_bounds.rho_rate_factor(2)/mass;
g.u_dot_bound=g.qdot_seg_max/rho_min+g.q_seg_max*nu_max/rho_min^2;
g.u_amp_bound=g.q_seg_max/rho_min;
g.amplitude_guard_pass=g.q_seg_max<=cell.qbar-0.01 ...
    && g.u_amp_bound<=min(p.force_max,-p.force_min);
g.slew_guard_pass=g.qdot_seg_max<=cell.qdotbar-0.01 ...
    && g.u_dot_bound<=p.force_slew ...
    && abs(g.q_start-q_previous)/dt<=cell.qdotbar-0.01;
g.pass=g.amplitude_guard_pass && g.slew_guard_pass;
end
