#!/bin/sh

# Define the IPFS path
export IPFS_PATH=/data/ipfs

# Check if the IPFS repository has already been initialized
if [ ! -f "$IPFS_PATH/config" ]; then
  echo "Initializing IPFS repository with server profile..."
  ipfs init --profile=server
else
  echo "IPFS repository already initialized."
fi

# Start the IPFS daemon
echo "Starting IPFS daemon..."
exec ipfs daemon --migrate=true