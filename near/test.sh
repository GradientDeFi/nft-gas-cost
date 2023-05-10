#!/bin/bash
set -e
mkdir res # create res directory

# build nep171 and copy .wasm to res
cargo build -p nep171 --target wasm32-unknown-unknown --release
cp target/wasm32-unknown-unknown/release/*.wasm ./res/

# run test which uses the .wasm program compiled above
cd gas-test
cargo run --example gas-test

# back to starting directory
cd ../