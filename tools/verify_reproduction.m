function report = verify_reproduction(package_root)
% Compare independently regenerated outputs with the published reference values.
if nargin<1, package_root=fileparts(fileparts(mfilename('fullpath'))); end
addpath(genpath(fullfile(package_root,'simulation')));
addpath(fullfile(package_root,'tools'));
output_root=fullfile(package_root,'outputs');
required={'exp1_cell_migration.mat','exp2_certificate_simplex.mat', ...
    'exp3_ckg_faults.mat','NORMAL_EXECUTION_AUDIT.csv','final_audit.txt', ...
    'semantic_runtime_cases.csv'};
for k=1:numel(required)
    if ~exist(fullfile(output_root,required{k}),'file')
        error('AEI:Reproduction','Missing generated output %s.',required{k});
    end
end
hash_report=verify_artifact_hashes(package_root);
a1=jsondecode(fileread(fullfile(output_root,'artifacts','C1_artifact.json')));
a2=jsondecode(fileread(fullfile(output_root,'artifacts','C2_artifact.json')));
x=load(fullfile(output_root,'exp1_cell_migration.mat'));e1=x.result;
y=load(fullfile(output_root,'exp2_certificate_simplex.mat'));e2=y.result;
z=load(fullfile(output_root,'exp3_ckg_faults.mat'));e3=z.result;

% These are comparison references, never generated data.
refs=struct('c1_margin',0.00816153,'c2_margin',0.00984715, ...
    'cell_rms',0.6527,'fixed_rms',0.6531,'normal_rows',70680, ...
    'failed_guards',0,'eligible_start',0,'eligible_end',17.0);
tol=struct('margin',5e-7,'rms',5e-4,'time',0.02);
T=readtable(fullfile(output_root,'NORMAL_EXECUTION_AUDIT.csv'));
authority=strcmp(string(T.authority),'N');
failed=authority & ~(T.amplitude_guard_pass & T.slew_guard_pass & ...
    T.domain_pass & T.artifact_valid & T.lmi_margin_pass & T.effective_delay_mode_pass);
normal_rows=nnz(authority);failed_guards=nnz(failed);
normal_outside=nnz(e1.adaptive.mode==1 & (~e1.adaptive.valid | e1.adaptive.cell_index<=0));
fault_types=string({e3.events.type});fault_pass=true;
for k=1:numel(e3.events)
    i=find(e3.trajectory.t>=e3.events(k).start,1);
    fault_pass=fault_pass && e3.trajectory.mode(i,1)==2 && ~e3.trajectory.valid(i,1);
end
finite_ok=e2.bound.eligible && abs(e2.bound.start_s-refs.eligible_start)<=tol.time ...
    && abs(e2.bound.end_s-refs.eligible_end)<=tol.time;
checks=struct();
checks.c1_margin=abs(a1.audited_min_margin-refs.c1_margin)<=tol.margin;
checks.c2_margin=abs(a2.audited_min_margin-refs.c2_margin)<=tol.margin;
checks.cell_rms=abs(e1.adaptive_metrics.rms-refs.cell_rms)<=tol.rms;
checks.fixed_rms=abs(e1.fixed_metrics.rms-refs.fixed_rms)<=tol.rms;
checks.normal_rows=normal_rows==refs.normal_rows;
checks.failed_guards=failed_guards==refs.failed_guards;
checks.fault_outcomes=fault_pass && numel(fault_types)==5 && e3.invalid_normal_count==0;
checks.normal_outside=normal_outside==0;
checks.finite_interval=finite_ok;
checks.simplex=all(e2.sample_margins>0) && all(e2.vertex_margins>0);
checks.hashes=hash_report.passed;
names=fieldnames(checks);pass=all(cellfun(@(n)checks.(n),names));
report=struct('passed',pass,'checks',checks,'references',refs, ...
    'observed',struct('c1_margin',a1.audited_min_margin, ...
    'c2_margin',a2.audited_min_margin,'cell_rms',e1.adaptive_metrics.rms, ...
    'fixed_rms',e1.fixed_metrics.rms,'normal_rows',normal_rows, ...
    'failed_guards',failed_guards,'normal_outside',normal_outside, ...
    'finite_interval',[e2.bound.start_s e2.bound.end_s], ...
    'fault_types',{fault_types}));
fid=fopen(fullfile(package_root,'BASIC_REPRODUCTION_RESULT.md'),'w');assert(fid>0);
cleaner=onCleanup(@()fclose(fid));
fprintf(fid,'# Basic reproduction result\n\n');
fprintf(fid,'`REPRODUCTION_BASIC = %s`\n\n',ternary(pass,'PASS','FAIL'));
fprintf(fid,'| Check | Observed | Reference | Result |\n|---|---:|---:|---|\n');
fprintf(fid,'| C1 margin | %.12g | %.12g | %s |\n',a1.audited_min_margin,refs.c1_margin,mark(checks.c1_margin));
fprintf(fid,'| C2 margin | %.12g | %.12g | %s |\n',a2.audited_min_margin,refs.c2_margin,mark(checks.c2_margin));
fprintf(fid,'| Cell-aware RMS (m) | %.7g | %.7g | %s |\n',e1.adaptive_metrics.rms,refs.cell_rms,mark(checks.cell_rms));
fprintf(fid,'| Fixed-C1 RMS (m) | %.7g | %.7g | %s |\n',e1.fixed_metrics.rms,refs.fixed_rms,mark(checks.fixed_rms));
fprintf(fid,'| Normal follower intervals | %d | %d | %s |\n',normal_rows,refs.normal_rows,mark(checks.normal_rows));
fprintf(fid,'| Failed normal guards | %d | %d | %s |\n',failed_guards,refs.failed_guards,mark(checks.failed_guards));
fprintf(fid,'| Cell-aware normal-outside-artifact samples | %d | 0 | %s |\n',normal_outside,mark(checks.normal_outside));
fprintf(fid,'| Eligible finite-fleet interval (s) | [%.3g, %.3g] | [0, 17] | %s |\n',e2.bound.start_s,e2.bound.end_s,mark(checks.finite_interval));
fprintf(fid,'| Five fault outcomes revoke normal authority | %d | 1 | %s |\n',checks.fault_outcomes,mark(checks.fault_outcomes));
fprintf(fid,'| Artifact hashes | %d | 1 | %s |\n',checks.hashes,mark(checks.hashes));
if ~pass, error('AEI:Reproduction','Basic reproduction checks failed.'); end
fprintf('Basic reproduction: PASS.\n');
end

function out=mark(ok)
if ok,out='PASS';else,out='FAIL';end
end
function out=ternary(cond,a,b)
if cond,out=a;else,out=b;end
end
