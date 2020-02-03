#!/bin/sh

flags=$*

# cd into the given rustc directory, build it, and then cd out.
compile() {
    cd $1
    ./x.py build $flags
    cd ..
}

# Download LLVM.
if [ ! -d llvm-project ]; then
    git clone -b llvmorg-10.0.0-rc1 https://github.com/llvm/llvm-project.git
    cd llvm-project
    mkdir build
    cd build
    cmake ../llvm -DLLVM_ENABLE_PROJECTS="clang" -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86"
    cd ../..
fi

# Dowload and setup Cargo with our patches.
if [ ! -d cargo ]; then
    git clone --branch rust-1.41.0 https://github.com/rust-lang/cargo.git
    # Apply the patch.
    git -C cargo apply ${PWD}/patches/cargo*
fi

# Download and set up the two rustc directories with our patches.
if [ ! -d rust-a ]; then
    git clone --branch 1.41.0 https://github.com/rust-lang/rust.git rust-a
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

# Build LLVM
cd llvm-project/build
make -j$(nproc)
cd ../..

# Have our builds use our cargo.
cat - > rust-a/config.toml <<EOF
[build]
cargo = "${PWD}/cargo/target/release/cargo"
full-bootstrap = true
extended = true
[target.x86_64-unknown-linux-gnu]
ar = "${PWD}/llvm-project/build/bin/llvm-ar"
cc = "${PWD}/llvm-project/build/bin/clang"
cxx = "${PWD}/llvm-project/build/bin/clang++"
[rust]
remap-debuginfo = true
debuginfo-level = 2
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
for file in $(find rust-a/build/x86_64-unknown-linux-gnu/stage2* -name "*.so" -o -name "*.rlib" -o -executable -type f); do
    other=${file/rust-a/rust-b}
    diff $file $other
done
