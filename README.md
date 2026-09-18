# AEI minimal reproduction package

This is the Phase A extraction of the final certificate-carrying truck
platoon reproduction materials. It contains the MATLAB source reachable from
the final experiment launcher, serialized C1/C2 artifacts and fault variants,
semantic representations, final reference datasets, and execution audits.

## Current status

Phase A extraction is complete. Independent reproduction verification,
toolbox/version checks, generated-output isolation, and hash-sum generation
are scheduled for Phase B.

## Layout

- `run_all.m` — package launcher.
- `simulation/` — reachable MATLAB source and runtime artifact copies.
- `artifacts/` — serialized C1/C2 artifacts and five fault variants per cell.
- `semantic/` — semantic parity checker and semantic source files.
- `audit/` — final technical audit and archived normal-execution audit.
- `reference_results/` — minimum final result datasets and summaries.
- `tools/` — independent verification tools added in Phase B.

The package uses relative paths only. It does not require Simulink or
TruckSim. The declared vehicle and scenario parameters are simulation
assumptions, not field measurements.
