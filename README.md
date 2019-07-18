# Reproducible rustc

This repository contains a proof of concept for building [rustc](https://github.com/rust-lang/rust) reproducibly.

The patches it uses are not all completely clean or even correct; they are intended to serve as a basis for discussion.  We would greatly appreciate any suggestions for how to improve them.

To get reproducible builds locally, either run `repro.sh` or

1. Apply the Cargo patch to Cargo and build it (tested with version 1.36.0).
2. Apply the other patches to two identical rustcs (tested with version 1.36.0).
3. Build the two rustcs with the Cargo from step 1.
4. Diff their stage 2s.

## Patches

We currently require the following patches to build rustc reproducibly.

* We need to pass `--remap-path-prefix` to all rustc processes.  For some reason, adding this to RUSTFLAGS in `.cargo/config` or the environment variable did not completely work.  Instead, we implement an idea proposed in <https://github.com/rust-lang/cargo/issues/5505> to remap `pwd` to the value of the CARGO_REGISTRY environment variable (if it is defined).  This patch is only a barebones implementation of that idea.

* We need to modify rustc to avoid hashing the `--sysroot` argument, which contains the current directory and so leads to non-reproducible builds when using different source paths.  As a proof of concept, we only hash the remapped sysroot instead of the original.  This is not completely correct, as the hash will stay the same if both the sysroot and the remapped path change, but it should demonstrate the idea.

* We modify librustc_llvm to avoid using the `__FILE__` macro, which can contain absolute paths.  We do this by propagating `NDEBUG` from the bootstrap if applicable.

* Similarly, we need to avoid using `__FILE__` when compiling compiler-rt.  This behavior cannot be disabled as easily as the one above, so as a hack we simply remove the `__FILE__` macro.
