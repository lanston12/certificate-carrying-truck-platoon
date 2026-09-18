function result=exp2_certificate_simplex()
p=base_parameters();cells=cell_parameters(p);c=cells(1);a=load_artifact('C1');
rng(p.seed);N=120;L=rand(N,3);L=L./sum(L,2);margin=zeros(N,1);
for k=1:N
    z=verify_simplex_sample(c,a,L(k,:));margin(k)=z.margin;
end
traj=simulate_platoon('adaptive');
% Eligible interval: scan a fixed-cell, all-normal run segment. The
% simulation may contain no such interval; then report explicitly.
eligible=all(traj.mode==1 & traj.cell_index==1 & traj.valid ...
    & traj.domain_pass & traj.amplitude_guard_pass & traj.slew_guard_pass,2);
starts=find(diff([false;eligible])==1);stops=find(diff([eligible;false])==-1);
if isempty(starts)
    bound=struct('eligible',false,'reason','no uninterrupted all-normal C1 segment');
else
    [~,k]=max(stops-starts);i0=starts(k);i1=stops(k);
    if i1-i0<10
        bound=struct('eligible',false,'reason','normal C1 segment too short');
    else
        bound=finite_fleet_bound(traj,i0,i1,c,a);
    end
end
result=struct('lambda_samples',L,'sample_margins',margin, ...
    'vertex_margins',a.vertex_margins,'trajectory',traj,'bound',bound);
root=fileparts(fileparts(mfilename('fullpath')));
output_root=fullfile(fileparts(root),'outputs');
save(fullfile(output_root,'exp2_certificate_simplex.mat'),'result','-v7.3');
fprintf('Exp2: min vertex %.6g, sampled %.6g; bound eligible %d\n', ...
    min(a.vertex_margins),min(margin),bound.eligible);
figure('Color','w','Position',[100 100 1050 680]);tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
nexttile;plot(1:N,margin,'.','MarkerSize',9);hold on;
yline(0,'k-','LineWidth',1.1);yline(min(a.vertex_margins),'r--','LineWidth',1.1);
ylim([-.004 max(margin)*1.08]);
ylabel('Margin = -\lambda_{max}(\Theta)');xlabel('Mixture sample');title('(a) Shared certificate');
nexttile;plot(traj.t,squeeze(traj.lambda(:,1,:)),'LineWidth',1.1);xlabel('Time (s)');ylabel('Weight');title('(b) Time-varying simplex');
nexttile;plot(L(:,1)+L(:,2)/2,sqrt(3)*L(:,2)/2,'.','MarkerSize',5);hold on;
plot([0 1 .5 0],[0 0 sqrt(3)/2 0],'k-');axis equal;xlim([-.05 1.05]);ylim([-.05 .92]);
title('(c) Convex samples');xlabel('Barycentric x');ylabel('Barycentric y');
nexttile;plot(traj.t,traj.q(:,2),'LineWidth',1.1);hold on;
yline(p.accel_virtual_limit,'k:');yline(-p.accel_virtual_limit,'k:');
xlabel('Time (s)');ylabel('Virtual command (m/s²)');title('(d) Command and guard');
set(findall(gcf,'Type','axes'),'FontSize',12,'LineWidth',.9);
exportgraphics(gcf,fullfile(output_root,'figures','exp2_simplex.pdf'),'ContentType','vector');
exportgraphics(gcf,fullfile(output_root,'figures','exp2_simplex.png'),'Resolution',600);
savefig(gcf,fullfile(output_root,'figures','exp2_simplex.fig'));close(gcf);
end

function b=finite_fleet_bound(s,i0,i1,c,a)
dt=s.dt;alpha=a.alpha;ad=a.alpha_d;dc=c.d_c;beta=alpha+ad/(1-dc);
arts={load_artifact('C1'),load_artifact('C2')};
delta=a.delta_port;r=1+delta/beta;
E=zeros(1,4);E0=zeros(1,4);omega_energy=zeros(1,4);
lhs=zeros(1,4);rhs=zeros(1,4);Hpi=zeros(1,4);Hc=zeros(1,5);V=zeros(1,4);
leader=sum(s.q(i0:i1,1).^2)*dt;
for i=1:5
    hist=zeros(round(c.tau_c/dt),1);
    for z=1:numel(hist)
        hist(z)=virtual_command_at(s.q,s.lambda,s.xi,s.mode,s.cell_index, ...
            arts,i,i0-(z-.5));
    end
    Hc(i)=ad/(1-dc)*sum(hist.^2)*dt;
end
for i=1:4
    y=squeeze(s.Y(i0,i,:));
    V(i)=y(:)'*a.P*y(:); % delay-integral terms nonnegative, conservative add below
    yd=squeeze(s.Y(max(1,i0-round(c.tau_c/dt)):i0,i,:));
    V(i)=V(i)+c.tau_c*max(eig(a.Q))*max(sum(yd.^2,2)) ...
        +c.tau_c^2*max(eig(a.R))*max(sum(diff(yd,1,1).^2,2))/dt^2;
    history=zeros(ceil(c.tau_a_max/dt),1);
    for z=1:numel(history)
        history(z)=virtual_command_at(s.q,s.lambda,s.xi,s.mode,s.cell_index, ...
            arts,i+1,i0-(z-.5));
    end
    Hpi(i)=(1+1/c.eta)*c.cpi^2*sum(history.^2)*dt;
    ext=zeros(i1-i0+1,3); % observed reduced-model residuals
    ii=i0:i1; jj=min(ii+1,size(s.state,1));
    acc=(squeeze(s.state(jj,i+1,2))-squeeze(s.state(ii,i+1,2)))/dt;
    accprev=(squeeze(s.state(jj,i,2))-squeeze(s.state(ii,i,2)))/dt;
    qdelay=zeros(numel(ii),1);
    for z=1:numel(ii)
        qdelay(z)=virtual_command_at(s.q,s.lambda,s.xi,s.mode,s.cell_index, ...
            arts,i+1,ii(z)-c.tau_a/dt);
    end
    ext(:,1)=acc-qdelay; % physical pressure/grade/drag residual w_i
    ext(:,2)=0; % synthetic efficacy and nominal delay coincide in this run
    ext(:,3)=accprev-s.q(ii,i);
    omega_energy(i)=sum(ext(:).^2)*dt;
    E0(i)=V(i)+Hpi(i)+Hc(i);
    E(i)=E0(i)+a.komega*omega_energy(i) ...
        +a.vartheta2/(1-dc)*leader;
    lhs(i)=sum(s.e(i0:i1,i).^2)*dt+beta*sum(s.q(i0:i1,i+1).^2)*dt;
    if i==1
        rhs(i)=(alpha+delta)*leader+E(i);
    else
        rhs(i)=r*rhs(i-1)+E(i);
    end
end
b=struct('eligible',true,'start_s',s.t(i0),'end_s',s.t(i1), ...
    'Hpi',Hpi,'Hc',Hc,'V0_upper',V,'E0_upper',E0, ...
    'omega_energy',omega_energy,'B',E,'lhs',lhs,'rhs',rhs, ...
    'ratio',lhs./rhs,'r',r,'beta',beta);
end
