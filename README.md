# Reproducible rustc

This repository contains a proof of concept for building [rustc](https://github.com/rust-lang/rust) reproducibly.

The patches it uses are not all completely clean or even correct; they are intended to serve as a basis for discussion.  We would greatly appreciate any suggestions for how to improve them.

To get reproducible builds locally, either run `repro.sh` or

1. Apply the patches to two identical rustcs (tested with version 1.40.0).
2. Build the two rustcs.
3. Diff their stage 2s.

## Patches

We currently require the following patch to build rustc reproducibly.

* We need to avoid using `__FILE__` when compiling compiler-rt.  This behavior cannot be disabled easily, so as a hack we simply remove the `__FILE__` macro.  GCC 8 and newer do not need this patch, nor do recent builds of LLVM.
