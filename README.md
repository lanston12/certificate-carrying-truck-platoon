# AEI minimal reproduction package

This package contains the MATLAB source, serialized C1/C2 artifacts and fault
variants, semantic representations, reference datasets, and execution audits
for the certificate-carrying truck platoon study.

## Current status

The scientific reproduction audit passed. The three experiments generated
70,680 normal follower intervals with zero failed normal guards. The release
archive includes the normal-execution audit CSV and the framework-figure
generator required by `run_all.m`.

## Reproduce

Use MATLAB R2022b or newer with Robust Control Toolbox and LMI Lab. From the
package root in MATLAB, run:

```matlab
run_all();
addpath('tools');
report = verify_reproduction();
assert(report.passed);
```

The regenerated data and figures are written under `outputs/`, which is not
tracked in Git. `BASIC_REPRODUCTION_RESULT.md` reports the independent checks.
The archived comparison datasets are under `reference_results/` and are not
used as simulation inputs.

## Layout

- `run_all.m` — package launcher.
- `simulation/` — reachable MATLAB source and runtime artifact copies.
- `artifacts/` — serialized C1/C2 artifacts and five fault variants per cell.
- `semantic/` — semantic parity checker and semantic source files.
- `audit/` — final technical audit and archived normal-execution audit.
- `reference_results/` — minimum final result datasets and summaries.
- `tools/` — independent verification tools.
- `audit/NORMAL_EXECUTION_AUDIT.csv` — archived per-interval guard audit.

The package uses relative paths only. It does not require Simulink or
TruckSim. The declared vehicle and scenario parameters are simulation
assumptions, not field measurements.
