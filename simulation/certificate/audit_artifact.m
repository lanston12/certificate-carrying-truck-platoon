function audit = audit_artifact(cell,vertices,P,Q,R)
% Independent numeric audit; no solver model objects are reused.
M=size(vertices,1); margins=zeros(M,1); residual=zeros(M,1);
for m=1:M
    Theta=build_theta(cell,vertices(m,:),P,Q,R);
    asym=norm(Theta-Theta','fro');
    residual(m)=asym;
    margins(m)=-max(eig((Theta+Theta')/2));
end
min_pqr=min([eig((P+P')/2);eig((Q+Q')/2);eig((R+R')/2)]);
feedback=zeros(M,1);
for m=1:M
    feedback(m)=sqrt(vertices(m,1:2)/P*vertices(m,1:2)');
end
feedforward=max(abs(vertices(:,3))+abs(vertices(:,4)))*cell.qbar;
qy=1.0; qell=0.5;
input_ok=max(feedback)<=qy && feedforward<=qell && qy+qell<=cell.qbar;
kappa_ok=cell.kappa_pi>(1+1/cell.eta)*cell.cpi^2;
audit=struct('margins',margins,'min_margin',min(margins), ...
    'min_storage_eig',min_pqr,'theta_asymmetry',max(residual), ...
    'max_feedback_slice',max(feedback),'feedforward_box_peak',feedforward, ...
    'input_ok',input_ok,'kappa_ok',kappa_ok,'accepted', ...
    min(margins)>1e-6 && min_pqr>1e-7 && input_ok && kappa_ok);
end
