#!/bin/bash

# Check if block number is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <block_number>"
    echo "Example: $0 323938801"
    exit 1
fi

# Run the Solana block fetcher scratch
cargo run --bin scratch_v2_hello_world -- --block-number "$1" 