function make_framework_figure()
root=fileparts(fileparts(mfilename('fullpath')));output_root=fullfile(fileparts(root),'outputs');
f=figure('Color','w','Position',[100 100 1100 260]);
axis([0 1 0 1]);axis off;hold on;
labels={'Degradation\nestimate','Cell\nlookup','Artifact\nvalidation', ...
    'Certified\nsimplex','Adaptive\nweights','Truck\nplant'};
x=linspace(.075,.925,6);w=.125;h=.27;
for i=1:6
    rectangle('Position',[x(i)-w/2,.53,w,h],'Curvature',.08, ...
        'FaceColor',[.93 .96 .99],'EdgeColor',[.13 .28 .42],'LineWidth',1.2);
    text(x(i),.665,sprintf(labels{i}),'HorizontalAlignment','center', ...
        'VerticalAlignment','middle','FontSize',10,'Color',[.08 .18 .27]);
    if i<6,quiver(x(i)+w/2+.008,.665,x(i+1)-x(i)-w-.016,0,0, ...
            'Color',[.25 .35 .43],'LineWidth',1.3,'MaxHeadSize',.65);end
end
rectangle('Position',[.39,.12,.23,.18],'Curvature',.08,'FaceColor',[.98 .94 .91], ...
    'EdgeColor',[.6 .33 .2],'LineWidth',1.2);
text(.505,.21,'Fallback authority','HorizontalAlignment','center','FontSize',10);
quiver(x(3),.53,0,-.22,0,'Color',[.6 .33 .2],'LineWidth',1.2);
quiver(.62,.21,.29,0,0,'Color',[.6 .33 .2],'LineWidth',1.2);
text(.5,.39,'Estimate \rightarrow inside \rightarrow Cell \rightarrow certifies \rightarrow Artifact \rightarrow admits \rightarrow Vertex', ...
    'HorizontalAlignment','center','FontSize',11,'Color',[.18 .31 .43]);
text(.5,.035,'Artifact \rightarrow fallsBackTo \rightarrow Fallback', ...
    'HorizontalAlignment','center','FontSize',11,'Color',[.52 .28 .17]);
exportgraphics(f,fullfile(output_root,'figures','framework.pdf'),'ContentType','vector');
exportgraphics(f,fullfile(output_root,'figures','framework.png'),'Resolution',600);
savefig(f,fullfile(output_root,'figures','framework.fig'));close(f);
end
