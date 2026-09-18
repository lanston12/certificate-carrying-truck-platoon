# Tools

After running `run_all()` from the package root, use:

```matlab
addpath('tools');
report = verify_reproduction();
assert(report.passed);
```

`verify_artifact_hashes.m` independently checks the serialized C1/C2
artifacts. Generated outputs are written under `outputs/`.
