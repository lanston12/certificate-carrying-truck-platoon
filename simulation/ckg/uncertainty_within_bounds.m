function inside=uncertainty_within_bounds(U,b)
fields={'mass_kg','headway_s','temp_C','pressure_Pa','rho_factor','tau_a_s'};
inside=true;
for k=1:numel(fields)
    name=fields{k};
    if ~isfield(U,name) || ~isfield(b,name),inside=false;return;end
    interval=U.(name);domain=b.(name);
    if numel(interval)~=2 || any(~isfinite(interval)),inside=false;return;end
    if numel(domain)==1,domain=[domain domain];end
    if interval(1)<domain(1) || interval(2)>domain(2)
        inside=false;return
    end
end
end
