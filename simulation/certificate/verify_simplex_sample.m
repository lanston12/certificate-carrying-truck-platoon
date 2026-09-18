function result = verify_simplex_sample(c,a,lambda)
assert(all(lambda>=0) && abs(sum(lambda)-1)<1e-12);
K=lambda*a.vertices.gains;
Theta=build_theta(c,K,a.P,a.Q,a.R);
result=struct('lambda',lambda,'K',K,'margin',-max(eig(Theta)), ...
    'simplex_residual',abs(sum(lambda)-1));
end
