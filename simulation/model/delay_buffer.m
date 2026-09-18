function value = delay_buffer(history,k,delay,dt)
% First-order interpolation of sampled history, with constant prehistory.
index = k-delay/dt;
if index <= 1, value=history(1,:); return; end
lo=floor(index); hi=min(lo+1,size(history,1));
f=index-lo; value=(1-f)*history(lo,:)+f*history(hi,:);
end
