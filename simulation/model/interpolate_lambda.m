function value=interpolate_lambda(lambda,lo,hi,f,j)
% Certified weights are first-order held between two sampled endpoints.
a=reshape(lambda(lo,j,:),1,[]);b=reshape(lambda(hi,j,:),1,[]);
value=(1-f)*a+f*b;
end
