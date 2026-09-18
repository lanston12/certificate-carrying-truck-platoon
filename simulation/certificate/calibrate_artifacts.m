function [artifacts,audits] = calibrate_artifacts()
% Freeze one searched nominal gain, create two nearby vertices per cell,
% solve common storage, independently audit, and serialize accepted files.
p=base_parameters(); cells=cell_parameters(p);
K=[0.9440508038221074 0.04491616569214696 0.00226653320194603 0];
spread=0.05;
vertices=[K;K+[spread 0.2*spread 0 0];K+[-spread -0.2*spread 0 0]];
root=fileparts(fileparts(mfilename('fullpath')));
package_root=fileparts(root);output_root=fullfile(package_root,'outputs');
artifact_dir=fullfile(output_root,'artifacts');
if ~exist(artifact_dir,'dir'), mkdir(artifact_dir); end
artifacts=cell(1,numel(cells)); audits=cell(1,numel(cells));
for j=1:numel(cells)
    c=cells(j);
    sol=solve_common_certificate(c,vertices);
    if ~sol.feasible
        error('Cell %s failed LMI Lab audit: t=%g, margin=%g',c.id,sol.tmin,sol.min_margin);
    end
    audit=audit_artifact(c,vertices,sol.P,sol.Q,sol.R);
    if ~audit.accepted
        error('Cell %s failed independent numeric audit: margin=%g',c.id,audit.min_margin);
    end
    a=struct();
    a.schema_version='1.0';
    a.vehicle_class_id='HD_TRUCK_20_28T';
    a.cell_id=c.id;
    a.artifact_id=[c.id '_SHARED_CERT_001'];
    a.version='1.0.0';
    a.creation_time='2026-09-17T00:00:00';
    a.expiry_time='2027-09-17T00:00:00';
    a.cell_bounds=struct('mass_kg',[min(p.masses) max(p.masses)], ...
        'headway_s',p.headway,'temp_C',c.temp_C,'pressure_Pa',c.pressure_Pa, ...
        'rho_factor',c.rho_factor,'rho_per_kg',[c.rho_factor(1)/max(p.masses) c.rho_factor(2)/min(p.masses)], ...
        'rho_rate_factor',[-c.rho_rate_factor c.rho_rate_factor], ...
        'tau_a_nominal_s',c.tau_a,'tau_a_max_s',c.tau_a_max, ...
        'tau_a_jitter_s',c.tau_jitter,'tau_a_s',c.tau_a_range, ...
        'tau_c_max_s',c.tau_c,'d_c',c.d_c);
    a.uncertainty_bounds=struct('temp_C',p.temp_est_error_C, ...
        'rho_factor',p.rho_est_error,'tau_a_s',p.tau_est_error_s);
    a.vertices=struct('ids',{{[c.id '_V1'],[c.id '_V2'],[c.id '_V3']}},'gains',vertices);
    a.P=sol.P; a.Q=sol.Q; a.R=sol.R;
    a.alpha=c.alpha; a.alpha_d=c.alpha_d; a.delta_port=c.delta_port;
    a.eta=c.eta; a.kappa_pi=c.kappa_pi;
    a.vartheta2=c.vartheta2; a.komega=c.komega;
    a.split_weight=c.split_weight;
    a.audited_min_margin=audit.min_margin;
    a.vertex_margins=audit.margins;
    a.solver_tmin=sol.tmin;
    a.storage_condition=sol.condition;
    a.input_limits=struct('force_min_N',p.force_min,'force_max_N',p.force_max, ...
        'virtual_abs_max',c.qbar,'feedback_slice',1.0,'feedforward_slice',0.5);
    a.slew_limits=struct('force_N_per_s',p.force_slew,'virtual_m_per_s3',c.qdotbar);
    a.fallback_parent='RADAR_BASELINE_001';
    a.integrity_hash=compute_artifact_hash(a);
    file=fullfile(artifact_dir,[c.id '_artifact.json']);
    fid=fopen(file,'w');assert(fid>0);cleanup=onCleanup(@()fclose(fid));
    fwrite(fid,jsonencode(a),'char');clear cleanup
    reloaded=jsondecode(fileread(file));
    if ~strcmp(compute_artifact_hash(reloaded),reloaded.integrity_hash)
        error('Round-trip integrity failed for %s',file);
    end
    artifacts{j}=a; audits{j}=audit;
    fprintf('%s: margin %.9g, tmin %.9g, cond %.3g, hash %s\n', ...
        c.id,audit.min_margin,sol.tmin,sol.condition,a.integrity_hash(1:12));
end
save(fullfile(output_root,'certificate_audits.mat'),'artifacts','audits','cells','vertices');
end
