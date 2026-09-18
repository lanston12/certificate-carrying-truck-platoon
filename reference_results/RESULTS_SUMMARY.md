# Pure-MATLAB results

## Reproduction

MATLAB R2022b with Robust Control Toolbox LMI Lab was used. From the manuscript directory:

```matlab
addpath(genpath('simulation'));
run_all();
```

`run_all.m` regenerates both JSON artifacts, the three `.mat` datasets, PDF/PNG/FIG experiment figures, and `audit/NORMAL_EXECUTION_AUDIT.csv`. The sampling and RK4 integration step is 0.02 s. Simplex weights and the normal virtual command are interpolated between samples; the 120-s plant runs are deterministic. Parameters are declared in `simulation/config/` and are scenario assumptions, not measured truck-identification data.

## Certificate and cells

| Cell | Temperature (°C) | Efficacy factor | Nominal actuator delay (s) | Common three-vertex minimum margin | Storage condition |
|---|---:|---:|---:|---:|---:|
| C1 | 25–115 | 0.88–1.02 | 0.12 | 0.00816153 | 196 |
| C2 | 100–300 | 0.68–0.96 | 0.18 | 0.00984715 | 226 |

Both cells use a 3-s headway and a 0.08-s communication delay. A normal artifact is applicable only when the complete uncertainty set fits both its cell and serialized bounds. The temperature, efficacy and delay half-widths are 1 °C, 0.005 and 0.01 s. LMI Lab finds one $P,Q,R$ triple per cell for all three frozen vertices. A separate numeric assembly checks every symmetric $\Theta$ eigenvalue, storage positivity, predictor allocation and input envelope. The certificate margin is $m(K)=-\lambda_{\max}(\Theta(K))$, positive for strict feasibility. The certificate uses $\delta=5$ and $\mu=0.5855203$; its finite-fleet recurrence ratio is $r=4.1478$. The former zero-slack certificate is outside this minimal runtime package.

## Experiment 1: degradation-cell migration

Four heterogeneous followers run on a 4% descent with repeated braking. Their uncertainty sets leave C1 and enter C2 between 17.02 and 27.02 s. Each controller passes from normal C1 to a 0.5-s fallback dwell and then normal C2. Across four followers, 100 vehicle samples are in fallback. The fixed C1 comparator remains empirically well behaved after its archived certificate is no longer applicable. The two controllers have nearly identical tracking; the result supports executable authority migration.

| Quantity | Fixed C1 | Cell-aware |
|---|---:|---:|
| Fleet RMS spacing error (m) | 0.6531 | 0.6527 |
| Normal time outside own artifact (vehicle-s) | 386.5 | 0 |
| Normal samples outside own artifact | 19,325 | 0 |
| C1/F/C2 transitions | 0 | 4 |

Data: `simulation/results/exp1_cell_migration.mat`. Figure: `simulation/figures/exp1_migration.pdf`.

## Experiment 2: shared-certificate simplex

All C1 vertices have positive margin; 120 deterministic random convex combinations are a numerical consistency check, with minimum margin 0.0200401. Online weights remain on the three-vertex simplex. Exact extrema of each planned FOH segment are checked before normal authority. Across three adaptive runs, all 70,680 normal follower-intervals pass amplitude, derivative, inverse-command, artifact, domain, LMI and effective-delay checks. Maximum planned amplitude is 0.7309811 m/s², maximum derivative 0.9430105 m/s³, and maximum inverse-command slew bound 30,012 N/s. The finite-fleet energy inequality holds on the uninterrupted all-normal C1 interval $[0,17.0]$ s. Its initial-history terms include the leader's held prehistory:

- $\max_i H_{\pi,i}(0)=5.4493\times10^{-8}$.
- $\max_{j=0,\ldots,3} H_{c,j}(0)=1.10\times10^{-3}$.
- External-port energies for followers 1–4: 3.83062, 3.84983, 3.88970, 3.88146.
- Terminal follower: $z_4=5.9501$, RHS $9.1894\times10^5$, ratio $6.4750\times10^{-6}$.

The large reserve comes from the broad external-residual allocation and geometric $r>1$. It should not be interpreted as empirical attenuation. Data: `simulation/results/exp2_certificate_simplex.mat`. Figure: `simulation/figures/exp2_simplex.pdf`.

## Experiment 3: CKG faults

Five one-second faults are injected while C1 normal authority is active: expiry, corrupted hash, wrong cell ID, missing $P$, and leader communication loss. Each produces its distinct validation reason and an empty vertex mask. State sampling, uncertainty construction, cell lookup and artifact validation precede the authority decision and command. All five transfer to fallback at the injection control sample; the control-period latency bound is 20 ms. Across the run, the count of invalid-artifact samples with normal authority is zero. This is an authority-interlock result; no stability or collision theorem is claimed for fallback.

Data: `simulation/results/exp3_ckg_faults.mat`. Figure: `simulation/figures/exp3_faults.pdf`.
The injected JSON payloads are retained in `artifacts/faults/`. Each is serialized and reloaded before the validator computes the mask.

`simulation/results/final_audit.txt` records the independent post-run checks: both hashes, all normal-mode cells and guards, the eligible finite-fleet bound, sampled simplex margins, and all five fault transitions passed.
Across normal flow the observed efficacy-factor rate peaks at 0.0022/s, below the archived 0.0035/s bound, and the physical force command does not clip at its declared limits.

## Semantic parity

The supplied JSON-LD context, SHACL shapes and SPARQL queries were executed using RDFLib and pySHACL against valid, expired, corrupted-hash, wrong-cell and missing-P C1 records. Valid, expired, wrong-cell and missing-P outcomes agree with MATLAB. SHACL checks hash-field presence and syntax; cryptographic digest recomputation is a separate MATLAB runtime predicate, so the corrupted-hash case is explicitly outside SHACL's scope. The result is archived in `simulation/results/semantic_parity.csv`.

## Interpretation limits

The certificates apply to the reduced fixed-cell predictor model on uninterrupted normal intervals. The physical plant and cell boundaries are transparent simulation assumptions. The whole migration trajectory is evaluated empirically; no single energy bound is carried through a cell change or fallback. The LMI certifies a finite fleet with a conservative geometric factor and does not establish string stability or collision invariance.
