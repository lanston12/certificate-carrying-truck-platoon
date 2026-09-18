function [valid,reason,mask] = validate_artifact(a,cell_id,U,time_iso,leader_available)
required={'schema_version','vehicle_class_id','cell_id','artifact_id','version', ...
    'creation_time','expiry_time','cell_bounds','uncertainty_bounds','vertices','P','Q','R', ...
    'alpha','alpha_d','delta_port','eta','kappa_pi','vartheta2','komega', ...
    'split_weight','audited_min_margin','input_limits','slew_limits', ...
    'fallback_parent','integrity_hash'};
mask=false(1,3); valid=false;
for k=1:numel(required)
    if ~isfield(a,required{k})
        reason=['missing_field:' required{k}];return
    end
end
if ~strcmp(a.schema_version,'1.0')
    reason='schema_version';return
end
if ~strcmp(a.cell_id,cell_id)
    reason='cell_mismatch';return
end
if ~strcmp(a.vehicle_class_id,'HD_TRUCK_20_28T')
    reason='vehicle_class';return
end
if ~strcmp(compute_artifact_hash(a),a.integrity_hash)
    reason='hash_mismatch';return
end
if strcmp(time_iso,a.expiry_time) || string(time_iso)>string(a.expiry_time) ...
        || string(time_iso)<string(a.creation_time)
    reason='expired_or_not_yet_valid';return
end
if ~leader_available
    reason='leader_loss';return
end
b=a.cell_bounds;
fields={'mass_kg','headway_s','temp_C','pressure_Pa','rho_factor','tau_a_s'};
for k=1:numel(fields)
    if ~isfield(U,fields{k}) || ~isfield(b,fields{k}) ...
            || numel(U.(fields{k}))~=2 || any(~isfinite(U.(fields{k})))
        reason=['missing_uncertainty_field:' fields{k}];return
    end
    interval=U.(fields{k});
    if interval(1)>interval(2)
        reason=['invalid_uncertainty_interval:' fields{k}];return
    end
end
required_error={'temp_C','rho_factor','tau_a_s'};
for k=1:numel(required_error)
    f=required_error{k};
    if ~isfield(a.uncertainty_bounds,f) || ~isscalar(a.uncertainty_bounds.(f)) ...
            || ~isfinite(a.uncertainty_bounds.(f)) || a.uncertainty_bounds.(f)<0
        reason=['missing_uncertainty_bound:' f];return
    end
end
if diff(U.temp_C)+1e-12<2*a.uncertainty_bounds.temp_C ...
        || diff(U.rho_factor)+1e-12<2*a.uncertainty_bounds.rho_factor ...
        || diff(U.tau_a_s)+1e-12<2*a.uncertainty_bounds.tau_a_s
    reason='uncertainty_underdeclared';return
end
if ~uncertainty_within_bounds(U,b)
    reason='uncertainty_outside_artifact';return
end
if ~isequal(size(a.vertices.gains),[3 4]) || numel(a.vertices.ids)~=3 ...
        || ~isequal(size(a.P),[2 2]) || ~isequal(size(a.Q),[2 2]) ...
        || ~isequal(size(a.R),[2 2])
    reason='shape_mismatch';return
end
if ~isfinite(a.audited_min_margin) || a.audited_min_margin<=0
    reason='nonpositive_margin';return
end
mask=true(1,3); valid=true; reason='valid';
end
