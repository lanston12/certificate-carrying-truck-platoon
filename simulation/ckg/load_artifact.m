function artifact=load_artifact(cell_id)
root=fileparts(fileparts(mfilename('fullpath')));
package_root=fileparts(root);output_root=fullfile(package_root,'outputs');
file=fullfile(output_root,'artifacts',[cell_id '_artifact.json']);
if ~exist(file,'file')
    file=fullfile(package_root,'artifacts',[cell_id '_artifact.json']);
end
artifact=jsondecode(fileread(file));
end
