function semantic_runtime_cases()
% MATLAB side of the fixed C1 semantic-parity audit.
root=fileparts(fileparts(mfilename('fullpath')));
package_root=fileparts(root);output_root=fullfile(package_root,'outputs');
dirpath=fullfile(output_root,'artifacts');
a=jsondecode(fileread(fullfile(dirpath,'C1_artifact.json')));
p=base_parameters();c=cell_parameters(p);c=c(1);
est=struct('mass_kg',mean(c.mass_kg),'headway_s',p.headway, ...
    'temp_C',mean(c.temp_C),'pressure_Pa',mean(c.pressure_Pa), ...
    'rho_factor',mean(c.rho_factor),'tau_a_s',c.tau_a);
U=build_uncertainty_set(est,p);
cases={'valid','stale','hash','wrong_cell','missing'};
file=fullfile(output_root,'semantic_runtime_cases.csv');
fid=fopen(file,'w');assert(fid>0);cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'case,matlab_valid,matlab_reason\n');
for k=1:numel(cases)
    if k==1
        record=a;
    else
        record=jsondecode(fileread(fullfile(dirpath,'faults', ...
            ['C1_' cases{k} '.json'])));
    end
    [valid,reason]=validate_artifact(record,'C1',U, ...
        '2026-09-17T12:00:00',true);
    fprintf(fid,'%s,%d,%s\n',cases{k},valid,reason);
end
end
