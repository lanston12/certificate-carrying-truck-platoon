# CHECKPOINT_A

## Phase A result

| Item | Status |
|---|---|
| Minimal package extracted | PASS |
| Final reachable MATLAB source included | PASS |
| C1/C2 artifacts and fault variants included | PASS |
| JSON-LD, SHACL, SPARQL, semantic checker included | PASS |
| Minimum reference results included | PASS |
| Final technical and normal-execution audits included | PASS |
| Absolute/private path scan | PASS |
| Git initialized | NO, as required |

## Package size

- Final included files: **88**.
- Payload size before the three control documents: approximately **21.8 MB**.
- Major excluded directories/files: `audit_pages/`, `tmp/`,
  `knowledge_artifact/`, generated figure collections, obsolete/search result
  datasets, manuscript/build files, and aggregate ZIP archives.

## Remaining issues

- Phase B must independently verify MATLAB version/toolbox availability,
  regenerate outputs in an isolated output area, compute SHA-256 sums, and
  compare headline metrics with the archived references.
- No scientific experiment was run in Phase A.

## Execute readiness

The extracted launcher and relative runtime paths are present, but the package
is **not yet certified ready to execute** until Phase B performs the required
toolbox/version and reproduction checks.
