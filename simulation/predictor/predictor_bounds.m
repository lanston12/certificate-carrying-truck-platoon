function b = predictor_bounds(q,dt,c)
% Explicit negative-time histories are zero in the supplied experiments.
b.cpi=c.cpi;
b.Hpi=(1+1/c.eta)*c.cpi^2*sum(q.^2)*dt;
b.Hc=c.alpha_d/(1-c.d_c)*sum(q.^2)*dt;
end
