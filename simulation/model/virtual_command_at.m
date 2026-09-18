function value=virtual_command_at(q,lambda,xi,mode,cell_index,artifacts,i,index)
% Evaluate the continuous virtual command at a fractional sample index.
% A normal interval executes its planned FOH segment even when the next
% sampled decision transfers to fallback or a new cell.
if index<=1,value=q(1,i);return;end
lo=floor(index);hi=min(lo+1,size(q,1));f=index-lo;
if hi==lo,value=q(lo,i);return;end
if i>1
    j=i-1;ci=cell_index(lo,j);
    if ci>0 && mode(lo,j)==1
        L=interpolate_lambda(lambda,lo,hi,f,j);
        x0=reshape(xi(lo,j,:),1,[]);x1=reshape(xi(hi,j,:),1,[]);
        x=(1-f)*x0+f*x1;
        value=(L*artifacts{ci}.vertices.gains)*x';
        return
    end
end
value=(1-f)*q(lo,i)+f*q(hi,i);
end
