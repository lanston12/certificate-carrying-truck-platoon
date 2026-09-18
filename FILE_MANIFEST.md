# Phase A file manifest

Generated once during Phase A extraction. The package contains 85 payload
files before the three Phase A control documents (`FILE_MANIFEST.md`,
`PRIVACY_AUDIT.md`, and `CHECKPOINT_A.md`) are added; the final Phase A count
is 88 files.

## Root launch and metadata

`run_all.m`, `README.md`, `REPRODUCIBILITY.md`, `.gitignore`,
`LICENSE_NOTE.md`.

## Executable MATLAB source

`simulation/` contains the 34 reachable MATLAB source files and the runtime
copies of the 15 serialized artifact/semantic files:

- `certificate/`: `audit_artifact.m`, `build_theta.m`,
  `calibrate_artifacts.m`, `final_run_audit.m`, `solve_common_certificate.m`,
  `verify_simplex_sample.m`, `write_normal_execution_audit.m`.
- `ckg/`: `build_uncertainty_set.m`, `cell_contains_uncertainty.m`,
  `compute_artifact_hash.m`, `load_artifact.m`, `select_cell.m`,
  `semantic_runtime_cases.m`, `uncertainty_within_bounds.m`,
  `validate_artifact.m`.
- `config/`: `base_parameters.m`, `cell_parameters.m`.
- `controller/`: `command_guards.m`, `controller_vertex.m`,
  `fallback_controller.m`, `segment_command_guard.m`, `simplex_policy.m`.
- `experiments/`: `exp1_cell_migration.m`, `exp2_certificate_simplex.m`,
  `exp3_ckg_faults.m`.
- `figures/`: `make_framework_figure.m`.
- `model/`: `delay_buffer.m`, `interpolate_lambda.m`, `simulate_platoon.m`,
  `thermal_pneumatic_rhs.m`, `truck_plant_rhs.m`, `virtual_command_at.m`.
- `predictor/`: `predictor_bounds.m`, `predictor_state.m`.
- `MATLAB_ENVIRONMENT.md`.
- `artifacts/`: the runtime copy of the C1/C2 artifacts, ten fault variants,
  JSON-LD context, SHACL shapes, and SPARQL queries.

## Final artifacts and semantic files

- `artifacts/`: C1/C2 final JSON artifacts, ten C1/C2 fault variants,
  `context.jsonld`, `shapes.ttl`, and `competency_queries.sparql` (15 files).
- `semantic/`: the same final semantic inputs plus
  `semantic_parity_check.py` (4 files).

## Audits and reference results

- `audit/FINAL_TECHNICAL_AUDIT.md`.
- `audit/NORMAL_EXECUTION_AUDIT.csv`.
- `reference_results/`: `exp1_cell_migration.mat`,
  `exp2_certificate_simplex.mat`, `exp3_ckg_faults.mat`,
  `certificate_audits.mat`, `final_audit.txt`, `semantic_parity.csv`,
  `semantic_runtime_cases.csv`, and `RESULTS_SUMMARY.md` (8 files).
- `tools/README.md` is a Phase B placeholder for independent verification
  tools.

## Deliberately excluded

- `simulation_matlab/results/`: generated/obsolete result collection; only
  the minimum final reference files are retained.
- `simulation_matlab/figures/`: generated figures and historical figure
  files; figures are not required for Phase A execution extraction.
- `audit_pages/`: historical screenshots and page-render QA images.
- `tmp/`: temporary files and caches.
- `knowledge_artifact/`: earlier illustrative negative artifact package,
  superseded by the final runtime semantic representation.
- `AEI_reproducibility_package.zip` and `AEI_submission_bundle.zip`:
  aggregate archives that would duplicate package contents.
- Manuscript source/PDF, DOCX, auxiliary LaTeX files, old experiments,
  search `.mat` files, IDE settings, and local build outputs.

Git was not initialized during Phase A.
