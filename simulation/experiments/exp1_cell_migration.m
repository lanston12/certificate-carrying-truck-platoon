function result=exp1_cell_migration()
root=fileparts(fileparts(mfilename('fullpath')));
fixed=simulate_platoon('fixed'); adaptive=simulate_platoon('adaptive');
mf=metrics(fixed);ma=metrics(adaptive);
result=struct('fixed',fixed,'adaptive',adaptive,'fixed_metrics',mf,'adaptive_metrics',ma);
output_root=fullfile(fileparts(root),'outputs');
save(fullfile(output_root,'exp1_cell_migration.mat'),'result','-v7.3');
fprintf('Exp1: RMS spacing fixed %.3f, adaptive %.3f m; C2 samples %d, fallback samples %d\n', ...
    mf.rms,ma.rms,nnz(adaptive.cell_index==2),nnz(adaptive.mode==2));
figure('Color','w','Position',[100 100 1050 680]);tt=tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
nexttile;plot(adaptive.t,adaptive.e,'LineWidth',1);hold on;plot(fixed.t,mean(fixed.e,2),'k--','LineWidth',1.4);
xlabel('Time (s)');ylabel('Spacing error (m)');title('(a) Cell-aware followers and fixed C1 mean');
nexttile;plot(adaptive.t,squeeze(adaptive.state(:,2:5,4)),'LineWidth',1);hold on;
yline(115,'k:');xlabel('Time (s)');ylabel('Brake temperature (°C)');title('(b) Thermal state');
nexttile;yyaxis left;
stairs(adaptive.t,adaptive.cell_index(:,1),'LineWidth',1.5);hold on;
stairs(adaptive.t,adaptive.mode(:,1)+2,'LineWidth',1.2);
ylim([0.5 4.5]);yticks(1:4);yticklabels({'C1','C2','N','F'});
ylabel('Selected cell / authority');
yyaxis right;stairs(adaptive.t,double(adaptive.c1_applicable(:,1)),'k--','LineWidth',1.4);
ylim([-.1 1.1]);yticks([0 1]);ylabel('C1 applicable');
xlabel('Time (s)');title('(c) Authority and C1 domain');
nexttile;plot(adaptive.t,squeeze(adaptive.lambda(:,1,:)),'LineWidth',1.2);
xlabel('Time (s)');ylabel('Weight');title('(d) Follower 1 simplex weights');
legend({'V1','V2','V3'},'Location','best');
set(findall(gcf,'Type','axes'),'FontSize',12,'LineWidth',.9);
exportgraphics(gcf,fullfile(output_root,'figures','exp1_migration.pdf'),'ContentType','vector');
exportgraphics(gcf,fullfile(output_root,'figures','exp1_migration.png'),'Resolution',600);
savefig(gcf,fullfile(output_root,'figures','exp1_migration.fig'));close(gcf);
end
function m=metrics(s)
m=struct('rms',sqrt(mean(s.e(:).^2)),'peak_positive',max(s.e(:)), ...
    'peak_negative',min(s.e(:)),'min_gap',min(s.gap(:)), ...
    'max_temperature',max(s.state(:,: ,4),[],'all'), ...
    'max_command',max(abs(s.q),[],'all'),'normal_fraction',mean(s.mode(:)==1));
end
