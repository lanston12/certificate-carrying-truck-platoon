function [Theta,blocks] = build_theta(cell,K,P,Q,R)
% Exact 14x14 assembly in the paper's chi ordering.
% K = [K_y(1),K_y(2),k_p,k_0].
assert(isequal(size(K),[1 4]));
assert(isequal(size(P),[2 2]) && isequal(size(Q),[2 2]) && isequal(size(R),[2 2]));
h = cell.h; ta = cell.tau_a; tc = cell.tau_c; dc = cell.d_c;
A = [0 1;0 0]; Bh = [-h;-1]; Ba = [ta-h;-1];
D = Bh; E = [0;1];
E1 = selector(1:2,14); E2 = selector(3:4,14);
E3 = selector(5:6,14); E4 = selector(7:8,14);
E5 = selector(9,14); E6 = selector(10,14);
E7 = selector(11,14); E8 = selector(12:14,14);
F = A*E1 + Ba*K(1:2)*E2 + E*E5 + Ba*K(3)*E6 + Ba*K(4)*E7 + [D Bh E]*E8;
He = [1 0]*E1;
Ha = K(1:2)*E2 + K(3)*E6 + K(4)*E7;
J = E1+E3-2*E4;
mu = cell.split_weight;
beta = cell.alpha+cell.alpha_d/(1-dc);
HeP = E1'*P*F + F'*P*E1;
Theta = HeP + E1'*Q*E1 + (1+cell.eta)*(He'*He) ...
    + (beta+cell.kappa_pi)*(Ha'*Ha) -(1-dc)*E2'*Q*E2 ...
    + tc^2*F'*R*F -mu*(E1-E2)'*R*(E1-E2) ...
    -mu*(E2-E3)'*R*(E2-E3) ...
    -(1-mu)*(E1-E3)'*R*(E1-E3)-3*(1-mu)*J'*R*J ...
    -(cell.alpha+cell.delta_port)*(E5'*E5)-cell.alpha_d*(E6'*E6) ...
    -cell.vartheta2*(E7'*E7)-cell.komega*(E8'*E8);
Theta = (Theta+Theta')/2;
blocks = struct('F',F,'He',He,'Ha',Ha,'E1',E1,'E2',E2,'E3',E3,'E4',E4, ...
    'E5',E5,'E6',E6,'E7',E7,'E8',E8,'J',J,'beta',beta);
end

function E = selector(indices,n)
E = zeros(numel(indices),n);
for k=1:numel(indices)
    E(k,indices(k)) = 1;
end
end
