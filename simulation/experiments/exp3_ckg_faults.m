function result=exp3_ckg_faults()
events=struct('start',{2,5,8,11,14},'stop',{3,6,9,12,15}, ...
    'type',{'stale','hash','wrong_cell','missing','leader_loss'});
s=simulate_platoon('adaptive',events);dt=s.dt;
latency=zeros(1,numel(events));
for f=1:numel(events)
    k=find(s.t>=events(f).start,1);
    first=find(s.mode(k:end,1)==2,1);
    latency(f)=(first-1)*dt;
end
invalid_normal=nnz(~s.valid & s.mode==1);
result=struct('events',events,'trajectory',s,'fallback_latency',latency, ...
    'invalid_normal_count',invalid_normal);
root=fileparts(fileparts(mfilename('fullpath')));
output_root=fullfile(fileparts(root),'outputs');
save(fullfile(output_root,'exp3_ckg_faults.mat'),'result','-v7.3');
fprintf('Exp3: invalid normal samples %d, max fallback latency %.3f s\n', ...
    invalid_normal,max(latency));
figure('Color','w','Position',[100 100 1050 680]);tiledlayout(4,1,'Padding','compact','TileSpacing','compact');
nexttile;stairs(s.t,s.valid(:,1),'LineWidth',1.4);hold on;
fault_labels={'Expiry','Hash','Cell','Field','Link'};
for f=1:numel(events)
    xline(events(f).start,'k:','LineWidth',.8);
    text((events(f).start+events(f).stop)/2,1.12,fault_labels{f}, ...
        'HorizontalAlignment','center','FontSize',9);
end
ylim([-.1 1.25]);ylabel('Valid');title('(a) Fault windows begin at dotted lines');
nexttile;stairs(s.t,s.cell_index(:,1),'LineWidth',1.3);hold on;stairs(s.t,s.mode(:,1)+2,'LineWidth',1.3);
ylim([.5 4.5]);yticks(1:4);yticklabels({'C1','C2','N','F'});
ylabel('Cell / mode');title('(b) Cell and authority');
nexttile;plot(s.t,squeeze(s.lambda(:,1,:)),'LineWidth',1.0);ylabel('Weight');title('(c) Admissible simplex');
nexttile;yyaxis left;plot(s.t,s.e(:,1),'LineWidth',1.0);ylabel('Error (m)');
yyaxis right;plot(s.t,s.gap(:,1),'k:');ylabel('Gap (m)');
legend({'Spacing error','Physical gap'},'Location','best');xlabel('Time (s)');title('(d) Physical response');
ax=findall(gcf,'Type','axes');for k=1:numel(ax),xlim(ax(k),[0 20]);end
set(ax,'FontSize',12,'LineWidth',.9);
exportgraphics(gcf,fullfile(output_root,'figures','exp3_faults.pdf'),'ContentType','vector');
exportgraphics(gcf,fullfile(output_root,'figures','exp3_faults.png'),'Resolution',600);
savefig(gcf,fullfile(output_root,'figures','exp3_faults.fig'));close(gcf);
end
