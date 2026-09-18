# Reproducibility scope

The package supports the finite-horizon, finite-fleet conditional certificate
and executable authority-interlock claims described by the manuscript. The
certificate applies on uninterrupted normal intervals within one certified
uncertainty cell. It does not claim global string stability, collision
invariance, fallback stability, tracking superiority, or field-calibrated
truck parameters.

The archived reference values are comparison targets, not generated outputs:

- C1 minimum certificate margin: `0.00816153`.
- C2 minimum certificate margin: `0.00984715`.
- Cell-aware RMS: `0.6527 m`.
- Fixed-C1 RMS: `0.6531 m`.
- Normal follower intervals: `70,680`.
- Failed normal pre-execution guards: `0`.
- Eligible finite-fleet interval: `[0, 17.0] s`.

Phase B must independently regenerate these values from source and compare
them with the archived files in `reference_results/`.
