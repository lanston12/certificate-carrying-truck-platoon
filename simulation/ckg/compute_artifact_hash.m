function hex = compute_artifact_hash(artifact)
% SHA-256 over sorted-field JSON payload, excluding integrity_hash.
if isfield(artifact,'integrity_hash')
    artifact=rmfield(artifact,'integrity_hash');
end
artifact=sort_fields_recursive(artifact);
payload=jsonencode(artifact);
md=java.security.MessageDigest.getInstance('SHA-256');
md.update(uint8(unicode2native(payload,'UTF-8')));
bytes=typecast(int8(md.digest()),'uint8');
hex=lower(reshape(dec2hex(bytes,2).',1,[]));
end

function value=sort_fields_recursive(value)
if isstruct(value)
    value=orderfields(value);
    names=fieldnames(value);
    for j=1:numel(value)
        for k=1:numel(names)
            name=names{k};
            value(j).(name)=sort_fields_recursive(value(j).(name));
        end
    end
elseif iscell(value)
    for k=1:numel(value)
        value{k}=sort_fields_recursive(value{k});
    end
end
end
