function out = simulate_platoon(kind,events)
% Sampled controller with FOH simplex weights and fixed-step RK4 plant.
% The fixed comparator deliberately executes C1 beyond its validity domain.
if nargin<2,events=struct('start',{},'stop',{},'type',{});end
p=base_parameters();cells=cell_parameters(p);A={load_artifact('C1'),load_artifact('C2')};
simulation_root=fileparts(fileparts(mfilename('fullpath')));
package_root=fileparts(simulation_root);
fault_dir=fullfile(package_root,'outputs','artifacts','faults');
if ~isempty(events) && ~exist(fault_dir,'dir'),mkdir(fault_dir);end
fault_names={'none','stale','hash','wrong_cell','missing','leader_loss'};
cache_valid=false(2,numel(fault_names));cache_reason=strings(2,numel(fault_names));
cache_mask=false(2,numel(fault_names),3);cache_bounds=cell(2,numel(fault_names));
for cc=1:2
    mid=struct('mass_kg',mean(cells(cc).mass_kg),'headway_s',p.headway, ...
        'temp_C',mean(cells(cc).temp_C),'pressure_Pa',mean(cells(cc).pressure_Pa), ...
        'rho_factor',mean(cells(cc).rho_factor),'tau_a_s',cells(cc).tau_a);
    U=build_uncertainty_set(mid,p);
    for ff=1:numel(fault_names)
        b=A{cc};leader=true;
        switch fault_names{ff}
            case 'stale',b.expiry_time='2025-01-01T00:00:00';b.integrity_hash=compute_artifact_hash(b);
            case 'hash',b.vertices.gains(1,1)=b.vertices.gains(1,1)+.01;
            case 'wrong_cell',b.cell_id=cells(3-cc).id;
            case 'missing',b=rmfield(b,'P');
            case 'leader_loss',leader=false;
        end
        if ~isempty(events) && ff>1
            file=fullfile(fault_dir,[cells(cc).id '_' fault_names{ff} '.json']);
            fid=fopen(file,'w');assert(fid>0);cleaner=onCleanup(@()fclose(fid));
            fwrite(fid,jsonencode(b),'char');clear cleaner
            b=jsondecode(fileread(file));
        end
        cache_bounds{cc,ff}=b.cell_bounds;
        [cache_valid(cc,ff),cache_reason(cc,ff),mask]= ...
            validate_artifact(b,cells(cc).id,U,'2026-09-17T12:00:00',leader);
        cache_mask(cc,ff,:)=mask;
    end
end
dt=p.dt;n=round(p.T/dt)+1;t=(0:n-1)'*dt;nv=5;
state=zeros(n,nv,4);q=zeros(n,nv);e=zeros(n,4);r=zeros(n,4);
Y=zeros(n,4,2);xi=zeros(n,4,4);lambda=zeros(n,4,3);
mode=zeros(n,4);cell_index=zeros(n,4);c1_applicable=false(n,4);tau_est=zeros(n,4);
valid=false(n,4);reasons=strings(n,4);gaps=zeros(n,4);margin=zeros(n,4,2);
q_seg_max=nan(n,4);qdot_seg_max=nan(n,4);u_dot_bound=nan(n,4);
amplitude_guard_pass=false(n,4);slew_guard_pass=false(n,4);
domain_pass=false(n,4);artifact_id=strings(n,4);
for i=1:nv
    state(1,i,:)=[-(i-1)*(p.standstill_gap+p.headway*22+p.vehicle_length),22,0,p.initial_temp_C];
end
lambda(1,:,:)=repmat(reshape([1/3 1/3 1/3],1,1,3),1,4,1);
if strcmp(kind,'fixed'),lambda(1,:,:)=repmat(reshape([1 0 0],1,1,3),1,4,1);end
last_cell=ones(1,4);dwell_until=zeros(1,4);
for k=1:n-1
    tk=t(k);q(k,1)=leader_profile(tk);
    for i=2:nv
        j=i-1;si=squeeze(state(k,i,:));sp=squeeze(state(k,i-1,:));
        e(k,j)=sp(1)-si(1)-p.vehicle_length-p.standstill_gap-p.headway*si(2);
        r(k,j)=sp(2)-si(2);gaps(k,j)=sp(1)-si(1)-p.vehicle_length;
        rho=max(.68,1-.0015*max(0,si(4)-80));
        if si(4)<=p.warm_delay_threshold_C,tau=.12;else,tau=.18;end
        tau_est(k,j)=tau;
        est=struct('mass_kg',p.masses(j),'headway_s',p.headway, ...
            'temp_C',si(4),'pressure_Pa',si(3),'rho_factor',rho,'tau_a_s',tau);
        U=build_uncertainty_set(est,p);
        c1_applicable(k,j)=cell_contains_uncertainty(U,cells(1));
        [id,~]=select_cell(U,cells);
        if isempty(id),ci=0;else,ci=find(strcmp({cells.id},id));end
        cell_index(k,j)=ci;
        if ci>0,art=A{ci};else,art=A{1};end
        fault=1;
        for f=1:numel(events)
            if tk>=events(f).start && tk<events(f).stop
                fault=find(strcmp(fault_names,events(f).type));
            end
        end
        if ci>0
            v=cache_valid(ci,fault) && uncertainty_within_bounds(U,cache_bounds{ci,fault});
            reason=char(cache_reason(ci,fault));
            if cache_valid(ci,fault) && ~v,reason='uncertainty_outside_artifact';end
            mask=squeeze(cache_mask(ci,fault,:))';
        else
            v=false;reason='uncertainty_not_contained';mask=false(1,3);
        end
        valid(k,j)=v;reasons(k,j)=string(reason);
        domain_pass(k,j)=ci>0 && uncertainty_within_bounds(U,art.cell_bounds);
        artifact_id(k,j)=string(art.artifact_id);
        if ci~=last_cell(j),dwell_until(j)=tk+p.dwell;last_cell(j)=ci;end
        yd=squeeze(delay_buffer(squeeze(Y(:,j,:)),k,p.comm_delay,dt));
        qp=virtual_command_at(q,lambda,xi,mode,cell_index,A,i-1,k-p.comm_delay/dt);
        q0=virtual_command_at(q,lambda,xi,mode,cell_index,A,1,k-p.comm_delay/dt);
        xi(k,j,:)=[yd(1),yd(2),qp,q0];
        old=reshape(lambda(k,j,:),1,[]);
        obs=[max(-2,min(2,e(k,j)/10));max(-2,min(2,r(k,j)/2));rho-.8];
        new=simplex_policy(old,obs,mask);
        normal_candidate=v && tk>=dwell_until(j) && ci>0;
        if strcmp(kind,'fixed')
            normal_candidate=true;old=[1 0 0];new=old;art=A{1};
            valid(k,j)=c1_applicable(k,j);
        end
        qprev=q(max(1,k-1),i);
        if normal_candidate && strcmp(kind,'fixed')
            desired=controller_vertex(old*art.vertices.gains,yd,qp,q0);
            [guard_fixed,mg,qguard]=command_guards(desired,qprev,dt,p);
            margin(k,j,:)=mg;
            if guard_fixed
                mode(k,j)=1;q(k,i)=qguard;
            else
                mode(k,j)=2;q(k,i)=fallback_at_sample(k,i,j,tau,qprev);
            end
        elseif normal_candidate
            % The 0.08-s delayed regressor at k+1 uses only history that
            % exists at decision k (communication delay exceeds dt).
            assert(p.comm_delay>=dt);
            yd1=squeeze(delay_buffer(squeeze(Y(:,j,:)),k+1,p.comm_delay,dt));
            qp1=virtual_command_at(q,lambda,xi,mode,cell_index,A,i-1,k+1-p.comm_delay/dt);
            q01=virtual_command_at(q,lambda,xi,mode,cell_index,A,1,k+1-p.comm_delay/dt);
            X0=reshape(xi(k,j,:),1,[]);
            X1=[yd1(1),yd1(2),qp1,q01];
            cell_current=cells(ci);
            guard=segment_command_guard(old,new,X0,X1,art.vertices.gains, ...
                dt,cell_current,art,p.masses(j),p,qprev);
            q_seg_max(k,j)=guard.q_seg_max;
            qdot_seg_max(k,j)=guard.qdot_seg_max;
            u_dot_bound(k,j)=guard.u_dot_bound;
            amplitude_guard_pass(k,j)=guard.amplitude_guard_pass;
            slew_guard_pass(k,j)=guard.slew_guard_pass;
            margin(k,j,:)=[cell_current.qbar-guard.q_seg_max, ...
                cell_current.qdotbar-guard.qdot_seg_max];
            if guard.pass
                mode(k,j)=1;q(k,i)=guard.q_start;
            else
                mode(k,j)=2;q(k,i)=fallback_at_sample(k,i,j,tau,qprev);
            end
        else
            mode(k,j)=2;q(k,i)=fallback_at_sample(k,i,j,tau,qprev);
            margin(k,j,:)=[p.accel_virtual_limit-abs(q(k,i)), ...
                p.accel_virtual_slew-abs(q(k,i)-qprev)/dt];
        end
        qfun=@(age)virtual_command_at(q,lambda,xi,mode,cell_index,A,i,k-age/dt);
        Y(k,j,:)=predictor_state([e(k,j);r(k,j)],qfun,k,tau,dt,p.headway);
        lambda(k+1,j,:)=new;
    end
    for i=1:nv
        s=squeeze(state(k,i,:));
        if i==1,mass=24000;tau=.12;else,mass=p.masses(i-1);tau=tau_est(k,i-1);end
        a=stage_rhs(s,mass,p,q,lambda,xi,mode,cell_index,A,i,k,tau);
        b=stage_rhs(s+dt*a/2,mass,p,q,lambda,xi,mode,cell_index,A,i,k+.5,tau);
        c=stage_rhs(s+dt*b/2,mass,p,q,lambda,xi,mode,cell_index,A,i,k+.5,tau);
        d=stage_rhs(s+dt*c,mass,p,q,lambda,xi,mode,cell_index,A,i,k+1,tau);
        state(k+1,i,:)=s+dt*(a+2*b+2*c+d)/6;
    end
end
e(end,:)=e(end-1,:);r(end,:)=r(end-1,:);gaps(end,:)=gaps(end-1,:);
q(end,:)=q(end-1,:);Y(end,:,:)=Y(end-1,:,:);xi(end,:,:)=xi(end-1,:,:);
mode(end,:)=mode(end-1,:);cell_index(end,:)=cell_index(end-1,:);
valid(end,:)=valid(end-1,:);reasons(end,:)=reasons(end-1,:);
domain_pass(end,:)=domain_pass(end-1,:);artifact_id(end,:)=artifact_id(end-1,:);
q_seg_max(end,:)=q_seg_max(end-1,:);qdot_seg_max(end,:)=qdot_seg_max(end-1,:);
u_dot_bound(end,:)=u_dot_bound(end-1,:);
amplitude_guard_pass(end,:)=amplitude_guard_pass(end-1,:);
slew_guard_pass(end,:)=slew_guard_pass(end-1,:);
c1_applicable(end,:)=c1_applicable(end-1,:);tau_est(end,:)=tau_est(end-1,:);
margin(end,:,:)=margin(end-1,:,:);
out=struct('t',t,'state',state,'q',q,'e',e,'r',r,'Y',Y,'xi',xi, ...
    'lambda',lambda,'mode',mode,'cell_index',cell_index,'valid',valid, ...
    'c1_applicable',c1_applicable,'tau_est',tau_est,'reasons',reasons, ...
    'gap',gaps,'guard_margin',margin,'dt',dt,'parameters',p, ...
    'q_seg_max',q_seg_max,'qdot_seg_max',qdot_seg_max, ...
    'u_dot_bound',u_dot_bound,'amplitude_guard_pass',amplitude_guard_pass, ...
    'slew_guard_pass',slew_guard_pass,'domain_pass',domain_pass, ...
    'artifact_id',artifact_id);

    function qf=fallback_at_sample(kk,ii,jj,tau_local,previous)
        q(kk,ii)=previous;
        qhist=@(age)virtual_command_at(q,lambda,xi,mode,cell_index,A,ii,kk-age/dt);
        ylocal=predictor_state([e(kk,jj);r(kk,jj)],qhist,kk,tau_local,dt,p.headway);
        qf=fallback_controller(ylocal(1),ylocal(2),p,previous,dt);
    end
end

function dz=stage_rhs(z,mass,p,q,lambda,xi,mode,cell_index,A,i,index,tau)
delayed=virtual_command_at(q,lambda,xi,mode,cell_index,A,i,index-tau/p.dt);
rho=max(.68,1-.0015*max(0,z(4)-80));
force=max(p.force_min,min(p.force_max,mass*delayed/rho));
dz=truck_plant_rhs(z,force,mass,p);
end

function a=leader_profile(t)
% Repeated braking and traction on the declared downhill road.
a=-.34+.15*sin(2*pi*t/36)-.28*exp(-((t-24)/5)^2) ...
    -.30*exp(-((t-55)/6)^2)-.32*exp(-((t-87)/5)^2);
end
