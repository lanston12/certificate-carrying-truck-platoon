function out = solve_common_certificate(cell,vertices)
% LMI Lab feasibility for frozen gains with one P,Q,R shared by all vertices.
% Always reassemble Theta numerically after solving.
eps_pos = 1e-7;
setlmis([]);
Pvar = lmivar(1,[2 1]); Qvar = lmivar(1,[2 1]); Rvar = lmivar(1,[2 1]);
for m=1:size(vertices,1)
    [~,b] = build_theta(cell,vertices(m,:),eye(2),eye(2),eye(2));
    F=b.F; E1=b.E1; E2=b.E2; E3=b.E3; E4=b.E4;
    E5=b.E5; E6=b.E6; E7=b.E7; E8=b.E8;
    J=b.J; He=b.He; Ha=b.Ha;
    fixed = (1+cell.eta)*(He'*He) + (b.beta+cell.kappa_pi)*(Ha'*Ha) ...
        -(cell.alpha+cell.delta_port)*(E5'*E5)-cell.alpha_d*(E6'*E6) ...
        -cell.vartheta2*(E7'*E7)-cell.komega*(E8'*E8);
    lmi = newlmi;
    lmiterm([lmi 1 1 Pvar],E1',F,'s');
    lmiterm([lmi 1 1 Qvar],E1',E1);
    lmiterm([lmi 1 1 Qvar],-(1-cell.d_c)*E2',E2);
    lmiterm([lmi 1 1 Rvar],cell.tau_c^2*F',F);
    mu=cell.split_weight;
    lmiterm([lmi 1 1 Rvar],-mu*(E1-E2)',(E1-E2));
    lmiterm([lmi 1 1 Rvar],-mu*(E2-E3)',(E2-E3));
    lmiterm([lmi 1 1 Rvar],-(1-mu)*(E1-E3)',(E1-E3));
    lmiterm([lmi 1 1 Rvar],-3*(1-mu)*J',J);
    lmiterm([lmi 1 1 0],fixed+eps_pos*eye(14));
end
for v=[Pvar Qvar Rvar]
    lmi = newlmi;
    lmiterm([lmi 1 1 0],eps_pos*eye(2));
    lmiterm([lmi 1 1 v],-1,1);
end
sys=getlmis;
try
    evalc('[tmin,x] = feasp(sys,[0 100 0 0 0]);');
catch ME
    out=struct('feasible',false,'tmin',inf,'reason',ME.message);
    return
end
out=struct('feasible',false,'tmin',tmin,'reason','');
if isempty(x) || ~isfinite(tmin)
    out.reason='No finite LMI Lab solution'; return
end
P=dec2mat(sys,x,Pvar); Q=dec2mat(sys,x,Qvar); R=dec2mat(sys,x,Rvar);
P=(P+P')/2; Q=(Q+Q')/2; R=(R+R')/2;
margins=zeros(size(vertices,1),1);
for m=1:size(vertices,1)
    Theta=build_theta(cell,vertices(m,:),P,Q,R);
    margins(m)=-max(eig((Theta+Theta')/2));
end
out.P=P; out.Q=Q; out.R=R; out.margins=margins;
out.min_margin=min(margins);
out.min_storage_eig=min([eig(P);eig(Q);eig(R)]);
out.condition=max([cond(P),cond(Q),cond(R)]);
out.feasible=tmin<0 && out.min_margin>1e-8 && out.min_storage_eig>1e-8 && out.condition<1e10;
if ~out.feasible
    out.reason='Independent margin, positive storage, conditioning or solver criterion failed';
end
end
