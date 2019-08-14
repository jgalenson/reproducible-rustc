# Reproducible rustc

This repository contains a proof of concept for building [rustc](https://github.com/rust-lang/rust) reproducibly.

The patches it uses are not all completely clean or even correct; they are intended to serve as a basis for discussion.  We would greatly appreciate any suggestions for how to improve them.

To get reproducible builds locally, either run `repro.sh` or

1. Apply the patches to two identical rustcs (tested with version 1.37.0).
2. Build the two rustcs.
3. Diff their stage 2s.

## Patches

We currently require the following patches to build rustc reproducibly.

* We can use the config option `remap-debuginfo` to pass `--remap-path-prefix` to rustc processes.  As currently implemented, this does not work for non-target crate types such as proc-macro, which causes some libraries to depend on the path.  We fix this by modifying it to work for everything.

* We need to modify rustc to avoid hashing the `--sysroot` argument, which contains the current directory and so leads to non-reproducible builds when using different source paths.

* We modify librustc_llvm to avoid using the `__FILE__` macro, which can contain absolute paths.  We do this by propagating `NDEBUG` from the bootstrap if applicable.

* Similarly, we need to avoid using `__FILE__` when compiling compiler-rt.  This behavior cannot be disabled as easily as the one above, so as a hack we simply remove the `__FILE__` macro.
