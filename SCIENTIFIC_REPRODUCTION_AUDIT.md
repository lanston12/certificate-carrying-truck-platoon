# Phase C — focused scientific consistency audit

## Exact discrepancy and cause

The Phase B basic verifier passed; the discrepancy was in `outputs/final_audit.txt`, not an executed normal guard. It reported planned derivative **17.1890611022 m/s³** instead of **0.943010504756 m/s³** (difference 16.246050597444; 1722.79% of the normal maximum), and inverse-command slew **537813.930646 N/s** instead of **30011.9935607 N/s** (difference 507801.9370853; 1692.00%). The first finite failed candidate occurs at **3.00 s, follower 1, C1, fallback F** in the faults run. The quoted derivative maximum is the **3.00 s, follower 2, C1, F** candidate; the quoted inverse-slew maximum is the **3.00 s, follower 3, C1, F** candidate. The latter exceeds 500000 N/s by 37813.930646 N/s, but is rejected before normal execution. All 70680 executed N intervals pass their guards.

Primary category: **A — verifier/reference-value bug** (specifically, an indexing error in the secondary final-audit calculation, plus its stale reference transcript). `verify_reproduction.m` did not contain an obsolete planned-metric reference; it already passed and did not compare these maxima. In `final_run_audit.m`, a `(numel(t)-1) × 4` N-mask indexed unsliced `numel(t) × 4` metric arrays. MATLAB linear indexing shifted columns 2–4 and admitted F candidates into the reported N maxima. This was an audit aggregation bug, not a control or unit error. No secondary category applies.

## Equation, execution and unit trace

`segment_command_guard.m` uses dimensionless θ∈[0,1], `ΔK=(L1−L0)·vertices`, and `Δξ=X1−X0` over the same 0.02-s FOH interval. It forms `c0=K0·X0`, `c1=K0·Δξ+ΔK·X0`, `c2=ΔK·Δξ`; `q_seg_max` checks both endpoints and an interior stationary point, while `qdot_seg_max=max(|c1|,|c1+2c2|)/dt` divides by seconds exactly once. Its continuity guard also checks `|q_start−q_previous|/dt ≤ qdotbar−0.01`. In `simulate_platoon.m`, the next delayed-regressor endpoint is read from existing history before the authority decision; `comm_delay=0.08 s ≥ dt=0.02 s` is asserted. A failed segment guard selects F before that interval. These match `AEI_manuscript.tex` Eqs. (policy-rate-map), (normal-guards), and (inverse-rate).

Here `q` is m/s², `qdot` m/s³, archived positive `rhohat_min=rho_factor_min/mass` is 1/kg, and `nuhat_rho_bar=0.0035/mass` is 1/(kg·s), with mass in kg. From `u=q/rhohat`, `du/dt=qdot/rhohat−q·rhodot/rhohat²`; absolute-value bounds give `qdot_seg_max/rhohat_min + q_seg_max·nuhat_rho_bar/rhohat_min²` in N/s, with no sign assumption. C1/C2 archive `qbar=qdotbar=1.5`, lower efficacy factors 0.88/0.68, and physical force slew 500000 N/s. There is no kN/N, tonne/kg, sample/second, or acceleration/force mismatch.

## Correction and post-fix result

Only the three final-audit metric arrays were sliced to `1:end-1,:` before applying the N-mask; the stale `reference_results/final_audit.txt` metric line was updated after independently confirming the CSV's N maxima and the unchanged manuscript/Supplement values. No controller, certificate, limit, simulation parameter, or manuscript claim changed.

Focused recalculation and the subsequent single full `run_all` both produced maximum planned `|q|=0.730981105621 m/s²`, `|qdot|=0.943010504756 m/s³`, and inverse-slew bound `30011.9935607 N/s` over 70680 N intervals, with zero failed N guards. `verify_reproduction.m` returned PASS after both checks; full-run MATLAB exit code was 0. The rounded `outputs/final_audit.txt` now matches `reference_results/final_audit.txt` exactly.

**Manuscript impact: NONE.**
