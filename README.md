# Reproducible rustc

This repository contains a script for building [rustc](https://github.com/rust-lang/rust) reproducibly.

All the patches it required have now been merged.

To get reproducible builds locally, either run `repro.sh` or

1. Apply the patches to two identical rustcs (tested with version 1.42.0).
2. Build the two rustcs.
3. Diff their stage 2s.
