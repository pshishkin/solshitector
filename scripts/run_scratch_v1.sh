#!/bin/bash

# Check if block number and output path are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <block_number> <output_path>"
    echo "Example: $0 2700000 ./block_2700000.json"
    exit 1
fi

# Run the IPFS block downloader scratch
cargo run --bin scratch_v1_ipfs_block_downloader -- --block-number "$1" --output "$2" 