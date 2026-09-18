function [id,reason] = select_cell(U,cells)
% Entire uncertainty box must fit; then smallest-cell deterministic tie-break.
hits=[]; volumes=[];
for k=1:numel(cells)
    c=cells(k);
    inside=cell_contains_uncertainty(U,c);
    if inside
        hits(end+1)=k; %#ok<AGROW>
        volumes(end+1)=diff(c.temp_C)*diff(c.pressure_Pa)*diff(c.rho_factor)*diff(c.tau_a_range); %#ok<AGROW>
    end
end
if isempty(hits)
    id=''; reason='uncertainty_not_contained'; return
end
[~,order]=sortrows([volumes(:),hits(:)],[1 2]);
id=cells(hits(order(1))).id;
reason='contained';
end
