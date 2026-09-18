function results = run_all()
% Reproduce the three final experiments into the isolated outputs directory.
package_root = fileparts(mfilename('fullpath'));
simulation_root = fullfile(package_root, 'simulation');
output_root = fullfile(package_root, 'outputs');
addpath(genpath(simulation_root));
check_environment();
for d = {'artifacts','results','figures'}
    path_d = fullfile(output_root, d{1});
    if ~exist(path_d, 'dir'), mkdir(path_d); end
end
copyfile(fullfile(package_root, 'artifacts'), fullfile(output_root, 'artifacts'), 'f');

[~, ~] = calibrate_artifacts();
make_framework_figure();
results.exp1 = exp1_cell_migration();
results.exp2 = exp2_certificate_simplex();
results.exp3 = exp3_ckg_faults();
semantic_runtime_cases();
save(fullfile(output_root, 'all_results.mat'), 'results', '-v7.3');
write_normal_execution_audit( ...
    {results.exp1.adaptive, results.exp2.trajectory, results.exp3.trajectory}, ...
    {'migration','simplex','faults'});
final_run_audit();
end

function check_environment()
if verLessThan('matlab','9.13')
    error('AEI:Environment','MATLAB R2022b or newer is required.');
end
v=ver;
if ~any(strcmp({v.Name},'Robust Control Toolbox'))
    error('AEI:Environment','Robust Control Toolbox is required.');
end
required={'setlmis','feasp','mincx'};
for k=1:numel(required)
    if exist(required{k},'file')~=2
        error('AEI:Environment','LMI Lab function %s is unavailable.',required{k});
    end
end
fprintf('Environment: MATLAB %s; Robust Control Toolbox and LMI Lab available.\n',version('-release'));
end
