function summary=write_normal_execution_audit(trajectories,names)
% One row per follower/control interval for each adaptive experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
file=fullfile(root,'outputs','NORMAL_EXECUTION_AUDIT.csv');
fid=fopen(file,'w');assert(fid>0);cleaner=onCleanup(@()fclose(fid));
fprintf(fid,['experiment,time_s,follower,cell,artifact_id,q_seg_max,' ...
    'qdot_seg_max,u_dot_bound,amplitude_guard_pass,slew_guard_pass,' ...
    'domain_pass,artifact_valid,lmi_margin_pass,effective_delay_mode_pass,authority\n']);
arts={load_artifact('C1'),load_artifact('C2')};
normal_count=0;failed_normal=0;max_q=0;max_rate=0;max_udot=0;
for z=1:numel(trajectories)
    s=trajectories{z};
    for k=1:numel(s.t)-1
        for j=1:4
            ci=s.cell_index(k,j);
            if ci>0
                cell_id=arts{ci}.cell_id;
                lmi=arts{ci}.audited_min_margin>0;
                delay_ok=abs(s.tau_est(k,j)-arts{ci}.cell_bounds.tau_a_nominal_s)<1e-12;
            else
                cell_id='none';lmi=false;delay_ok=false;
            end
            is_normal=s.mode(k,j)==1;
            passed=s.amplitude_guard_pass(k,j) && s.slew_guard_pass(k,j) ...
                && s.domain_pass(k,j) && s.valid(k,j) && lmi && delay_ok;
            if is_normal
                normal_count=normal_count+1;
                failed_normal=failed_normal+~passed;
                max_q=max(max_q,s.q_seg_max(k,j));
                max_rate=max(max_rate,s.qdot_seg_max(k,j));
                max_udot=max(max_udot,s.u_dot_bound(k,j));
            end
            if is_normal,authority='N';else,authority='F';end
            fprintf(fid,'%s,%.2f,%d,%s,%s,%.12g,%.12g,%.12g,%d,%d,%d,%d,%d,%d,%s\n', ...
                names{z},s.t(k),j,cell_id,char(s.artifact_id(k,j)), ...
                s.q_seg_max(k,j),s.qdot_seg_max(k,j),s.u_dot_bound(k,j), ...
                s.amplitude_guard_pass(k,j),s.slew_guard_pass(k,j), ...
                s.domain_pass(k,j),s.valid(k,j),lmi,delay_ok,authority);
        end
    end
end
summary=struct('normal_intervals',normal_count,'failed_normal_intervals', ...
    failed_normal,'max_q_seg',max_q,'max_qdot_seg',max_rate, ...
    'max_u_dot_bound',max_udot,'file',file);
assert(failed_normal==0,'A normal interval failed an execution guard');
end
