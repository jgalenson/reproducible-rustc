#!/bin/sh

# cd into the given rustc directory, build it, and then cd out.
compile() {
    cd $1
    ./x.py build
    cd ..
}

# Dowload and setup Cargo with our patches.
if [ ! -d cargo ]; then
    git clone --branch rust-1.37.0 https://github.com/rust-lang/cargo.git
    # Apply the patch.
    git -C cargo apply ${PWD}/patches/cargo*
fi

# Download and set up the two rustc directories with our patches.
if [ ! -d rust-a ]; then
    git clone --branch 1.37.0 https://github.com/rust-lang/rust.git rust-a
    # Run x.py and do nothing so it downloads LLVM and other tools.
    cd rust-a
    ./x.py
    cd ..
    # Apply the patches.
    git -C rust-a apply ${PWD}/patches/rustc*
    git -C rust-a/src/llvm-project apply ${PWD}/patches/llvm*
    # Make a clean copy.
    rm -rf rust-a/build
    cp -r rust-a rust-b
fi

# Have our builds use our cargo.
cat - > rust-a/config.toml <<EOF
[build]
cargo = "${PWD}/cargo/target/release/cargo"
full-bootstrap = true
extended = true
[rust]
remap-debuginfo = true
EOF
cp rust-a/config.toml rust-b/config.toml

# Build Cargo.
cd cargo
cargo build --release
cd ..

# Build rust-a and rust-b.
# Build them in parallel for maximum efficiency.
compile rust-a &
compile rust-b &
wait

# Diff their stage 2s.
echo "Diffing the two rusts.  Let's hope they're identical!"
diff -ur rust-{a,b}/build/x86_64-unknown-linux-gnu/stage2
