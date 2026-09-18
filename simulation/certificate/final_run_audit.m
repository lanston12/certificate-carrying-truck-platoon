function audit=final_run_audit()
% Independent outcome checks over the saved runs, without re-simulating.
root=fileparts(fileparts(mfilename('fullpath')));output_root=fullfile(fileparts(root),'outputs');
x=load(fullfile(output_root,'exp1_cell_migration.mat'));s=x.result.adaptive;
y=load(fullfile(output_root,'exp2_certificate_simplex.mat'));e2=y.result;
z=load(fullfile(output_root,'exp3_ckg_faults.mat'));e3=z.result;
a1=load_artifact('C1');a2=load_artifact('C2');
hash_ok=strcmp(compute_artifact_hash(a1),a1.integrity_hash) ...
    && strcmp(compute_artifact_hash(a2),a2.integrity_hash);
normal=s.mode==1;
normal_valid=all(s.valid(normal)==1) && all(s.cell_index(normal)>0);
cell_containment=true;rho_rate_peak=0;force_limit_ok=true;foh_rate_peak=0;
p=s.parameters;cells=cell_parameters(p);arts={a1,a2};
for j=1:4
    temp=squeeze(s.state(:,j+1,4)); pressure=squeeze(s.state(:,j+1,3));
    rho=max(.68,1-.0015*max(0,temp-80));
    rho_rate_peak=max(rho_rate_peak,max(abs(diff(rho)))/s.dt);
    for k=find(normal(:,j))'
        ci=s.cell_index(k,j);
        est=struct('mass_kg',p.masses(j),'headway_s',p.headway, ...
            'temp_C',temp(k),'pressure_Pa',pressure(k), ...
            'rho_factor',rho(k),'tau_a_s',s.tau_est(k,j));
        U=build_uncertainty_set(est,p);
        cell_containment=cell_containment && cell_contains_uncertainty(U,cells(ci)) ...
            && uncertainty_within_bounds(U,arts{ci}.cell_bounds);
    end
    for k=1:numel(s.t)-1
        ci=s.cell_index(k,j);
        if ci>0 && ci==s.cell_index(k+1,j) && all(s.mode(k:k+1,j)==1)
            L0=reshape(s.lambda(k,j,:),1,[]);L1=reshape(s.lambda(k+1,j,:),1,[]);
            X0=reshape(s.xi(k,j,:),1,[]);X1=reshape(s.xi(k+1,j,:),1,[]);
            G=arts{ci}.vertices.gains;dK=(L1-L0)*G;dX=X1-X0;
            rates=[dK*X0'+(L0*G)*dX',dK*X1'+(L1*G)*dX']/s.dt;
            foh_rate_peak=max(foh_rate_peak,max(abs(rates)));
        end
    end
    force=s.parameters.masses(j)*s.q(:,j+1)./rho;
    force_limit_ok=force_limit_ok && all(force(normal(:,j))>=s.parameters.force_min) ...
        && all(force(normal(:,j))<=s.parameters.force_max);
end
rho_rate_ok=rho_rate_peak<=max([a1.cell_bounds.rho_rate_factor(2), ...
    a2.cell_bounds.rho_rate_factor(2)])+1e-10;
normal_margin=all(s.guard_margin(repmat(normal,1,1,2))>0);
executed={s,e2.trajectory,e3.trajectory};
segment_guard_ok=true;all_normal_intervals=0;failed_normal_intervals=0;
max_planned_q=0;max_planned_rate=0;max_inverse_slew=0;
for z=1:numel(executed)
    v=executed{z};nmask=v.mode(1:end-1,:)==1;
    ok=v.amplitude_guard_pass(1:end-1,:) & v.slew_guard_pass(1:end-1,:) ...
        & v.domain_pass(1:end-1,:) & v.valid(1:end-1,:);
    all_normal_intervals=all_normal_intervals+nnz(nmask);
    failed_normal_intervals=failed_normal_intervals+nnz(nmask & ~ok);
    segment_guard_ok=segment_guard_ok && ~any(nmask & ~ok,'all');
    q_seg=v.q_seg_max(1:end-1,:);
    qdot_seg=v.qdot_seg_max(1:end-1,:);
    u_dot=v.u_dot_bound(1:end-1,:);
    max_planned_q=max(max_planned_q,max(q_seg(nmask)));
    max_planned_rate=max(max_planned_rate,max(qdot_seg(nmask)));
    max_inverse_slew=max(max_inverse_slew,max(u_dot(nmask)));
end
foh_rate_ok=foh_rate_peak<=p.accel_virtual_slew+1e-9;
normal_q=abs(s.q(:,2:5));normal_q_ok=all(normal_q(normal)<=s.parameters.accel_virtual_limit+1e-9);
bound_ok=e2.bound.eligible && all(e2.bound.rhs>=e2.bound.lhs);
simplex_ok=all(e2.sample_margins>0) && all(e2.vertex_margins>0) ...
    && all(abs(sum(e2.lambda_samples,2)-1)<1e-12);
fault_ok=e3.invalid_normal_count==0;
reasons=cell(1,numel(e3.events));
for j=1:numel(e3.events)
    k=find(e3.trajectory.t>=e3.events(j).start,1);
    reasons{j}=char(e3.trajectory.reasons(k,1));
    fault_ok=fault_ok && e3.trajectory.mode(k,1)==2 && ~e3.trajectory.valid(k,1);
end
audit=struct('hash_ok',hash_ok,'normal_valid',normal_valid, ...
    'cell_containment',cell_containment,'rho_rate_ok',rho_rate_ok, ...
    'rho_rate_peak',rho_rate_peak,'force_limit_ok',force_limit_ok, ...
    'normal_margin',normal_margin,'normal_q_ok',normal_q_ok, ...
    'segment_guard_ok',segment_guard_ok, ...
    'all_normal_intervals',all_normal_intervals, ...
    'failed_normal_intervals',failed_normal_intervals, ...
    'max_planned_q',max_planned_q,'max_planned_rate',max_planned_rate, ...
    'max_inverse_slew',max_inverse_slew, ...
    'foh_rate_ok',foh_rate_ok,'foh_rate_peak',foh_rate_peak, ...
    'bound_ok',bound_ok,'simplex_ok',simplex_ok,'fault_ok',fault_ok, ...
    'fault_reasons',{reasons},'normal_samples',nnz(normal), ...
    'fallback_samples',nnz(s.mode==2),'min_sample_margin',min(e2.sample_margins));
assert(all([hash_ok normal_valid cell_containment rho_rate_ok force_limit_ok ...
    normal_margin normal_q_ok segment_guard_ok foh_rate_ok bound_ok simplex_ok fault_ok]));
file=fullfile(output_root,'final_audit.txt');fid=fopen(file,'w');assert(fid>0);
cleaner=onCleanup(@()fclose(fid));
fprintf(fid,'Hashes valid: %d\nNormal samples use valid cells: %d\n',hash_ok,normal_valid);
fprintf(fid,'Normal samples inside artifact bounds: %d\nEfficacy-rate bound valid: %d (peak %.7g /s)\n', ...
    cell_containment,rho_rate_ok,rho_rate_peak);
fprintf(fid,'Normal physical force unsaturated: %d\n',force_limit_ok);
fprintf(fid,'Normal guards positive: %d\nNormal virtual amplitude valid: %d\n',normal_margin,normal_q_ok);
fprintf(fid,'Planned-segment guards valid: %d; normal intervals %d; failed %d\n', ...
    segment_guard_ok,all_normal_intervals,failed_normal_intervals);
fprintf(fid,'Planned maxima: q %.7g m/s^2, qdot %.7g m/s^3, inverse slew %.7g N/s\n', ...
    max_planned_q,max_planned_rate,max_inverse_slew);
fprintf(fid,'FOH virtual-command rate valid: %d (peak %.7g m/s^3)\n',foh_rate_ok,foh_rate_peak);
fprintf(fid,'Eligible finite-fleet bound holds: %d\nSimplex margins positive: %d\n',bound_ok,simplex_ok);
fprintf(fid,'All information faults revoke normal authority: %d\n',fault_ok);
fprintf(fid,'Normal vehicle samples: %d\nFallback vehicle samples: %d\n',audit.normal_samples,audit.fallback_samples);
for j=1:numel(reasons),fprintf(fid,'%s: %s\n',e3.events(j).type,reasons{j});end
end
