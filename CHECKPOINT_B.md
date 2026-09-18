# CHECKPOINT_B

## Basic reproduction

| Requirement | Result |
|---|---|
| MATLAB R2022b detected | PASS |
| Robust Control Toolbox detected | PASS |
| LMI Lab `setlmis`/`feasp`/`mincx` available | PASS |
| Three final experiments regenerated | PASS |
| C1/C2 artifacts reassembled and serialized | PASS |
| Independent artifact hash verification | PASS |
| Normal follower intervals | 70,680 |
| Failed normal pre-execution guards | 0 |
| Cell-aware normal-outside-artifact samples | 0 |
| Five fault outcomes revoke normal authority | PASS |
| Eligible finite-fleet interval | `[0, 17.0] s` |
| `REPRODUCTION_BASIC` | **PASS** |

Generated runtime files are isolated under `outputs/`. The publishable
package hash list is `SHA256SUMS.txt`; it excludes only the ignored runtime
directory `outputs/` and the hash list itself.

## Scientific consistency issue for Sol review

The regenerated `outputs/final_audit.txt` agrees with the archived
`reference_results/final_audit.txt`:

- planned-segment maximum derivative: `17.18906 m/s^3`;
- planned inverse-command slew: `537813.9 N/s`;
- separate FOH virtual-command rate: `0.9430105 m/s^3`.

However, the included `reference_results/RESULTS_SUMMARY.md` and
`audit/FINAL_TECHNICAL_AUDIT.md` describe `0.9430105 m/s^3` and approximately
`30,012 N/s` as the planned-segment derivative and inverse-slew maxima. This
is a material metric-label/documentation inconsistency. No scientific source
or manuscript claim was changed in Phase B; Phase C must reconcile which
quantity is reported before the release can be considered scientifically
consistent.

## Phase B disposition

The basic reproduction test passes, but Phase B is not scientifically clear
for release until the discrepancy above is resolved by the Sol audit.
