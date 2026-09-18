function report = verify_artifact_hashes(package_root)
% Independently verify serialized C1/C2 artifact fields and SHA-256 hashes.
if nargin<1, package_root=fileparts(fileparts(mfilename('fullpath'))); end
addpath(genpath(fullfile(package_root,'simulation')));
addpath(fullfile(package_root,'tools'));
artifact_dir=fullfile(package_root,'outputs','artifacts');
if ~exist(artifact_dir,'dir'), error('AEI:Artifacts','Output artifact directory is missing.'); end
ids={'C1','C2'};
report=struct('passed',false,'artifacts',struct('id',{},'hash',{},'margin',{}));
for k=1:numel(ids)
    file=fullfile(artifact_dir,[ids{k} '_artifact.json']);
    if ~exist(file,'file'), error('AEI:Artifacts','Missing %s.',file); end
    a=jsondecode(fileread(file));
    required={'schema_version','cell_id','artifact_id','version', ...
        'expiry_time','cell_bounds','uncertainty_bounds','vertices', ...
        'P','Q','R','audited_min_margin','integrity_hash'};
    present=cellfun(@(f)isfield(a,f),required);
    hash_ok=strcmp(compute_artifact_hash(a),a.integrity_hash);
    margin_ok=isfinite(a.audited_min_margin) && a.audited_min_margin>0;
    id_ok=strcmp(a.cell_id,ids{k});
    if ~all(present) || ~hash_ok || ~margin_ok || ~id_ok
        error('AEI:Artifacts','Artifact %s failed required-field, hash, margin, or cell checks.',ids{k});
    end
    report.artifacts(k).id=ids{k};
    report.artifacts(k).hash=a.integrity_hash;
    report.artifacts(k).margin=a.audited_min_margin;
end
report.passed=true;
fprintf('Artifact hashes: PASS (C1 %.9g, C2 %.9g).\n', ...
    report.artifacts(1).margin,report.artifacts(2).margin);
end
