function q = controller_vertex(K,y_delayed,qpred_delayed,qleader_delayed)
q=K(1:2)*y_delayed(:)+K(3)*qpred_delayed+K(4)*qleader_delayed;
end
