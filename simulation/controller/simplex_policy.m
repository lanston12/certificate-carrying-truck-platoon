function lambda = simplex_policy(lambda_old,observation,enabled)
% Deterministic affine logits and a rate-limited convex update.
logits=[-0.5 0.6 -0.6;0.2 -0.4 0.2;0.5 -0.2 0.4]*observation(:);
logits(~enabled(:))=-Inf;
if ~any(enabled), lambda=zeros(1,3); return; end
z=exp(logits-max(logits)); target=(z/sum(z))';
lambda=0.94*lambda_old+0.06*target;
lambda(~enabled)=0; lambda=lambda/sum(lambda);
end
