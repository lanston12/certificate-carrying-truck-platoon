# MATLAB environment audit

Audited on the local host before simulation.

| Component | Detected state | Consequence |
|---|---|---|
| MATLAB | R2022b, version 9.13.0.2049777 | Pure `.m` scripts and fixed-step integration available. |
| Robust Control Toolbox | 6.11.2; license test passed | LMI Lab `setlmis`, `feasp`, and `mincx` are available. Primary frozen-gain SDP route. |
| Optimization Toolbox | 9.4; license test passed | `fmincon` available for optional gain search. |
| YALMIP / CVX | Not found on MATLAB path | Not used. |
| SeDuMi / SDPT3 / MOSEK | Not found on MATLAB path | Not used. |
| Simulink | Installed, but excluded by task | No model, block, or Simulink API will be used. |

The certificate problem is affine in the shared storage matrices and scalar supply weights after gains are frozen. LMI Lab can therefore test a candidate library without an external SDP package. Every accepted result must be reassembled as an ordinary MATLAB numeric matrix and checked with `eig((Theta+Theta')/2)`; solver feasibility alone is insufficient. If no strictly positive independent margin is found, the artifact is rejected and the experiment is reported as blocked rather than assigned a positive margin.
