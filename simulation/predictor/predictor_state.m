function y = predictor_state(x,q_history,k,tau_a,dt,h)
% Eq. (10), rectangle quadrature of the actual held virtual command.
n=max(1,round(tau_a/dt)); integral=0;
for j=0:n-1
    s=(j+0.5)*dt;
    if isa(q_history,'function_handle'),q=q_history(s);else,q=delay_buffer(q_history,k,s,dt);end
    integral=integral+(tau_a-h-s)*q*dt;
end
q_integral=0;
for j=0:n-1
    s=(j+0.5)*dt;
    if isa(q_history,'function_handle'),q=q_history(s);else,q=delay_buffer(q_history,k,s,dt);end
    q_integral=q_integral-q*dt;
end
y=x+[integral;q_integral];
end
