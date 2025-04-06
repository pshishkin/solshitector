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

# Configure API to listen on all interfaces
echo "Configuring IPFS API and Gateway..."
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# Configure CORS headers for API
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST", "GET", "OPTIONS"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["X-Requested-With", "Range", "User-Agent", "X-Requested-With", "Origin", "Content-Type"]'
ipfs config --json API.HTTPHeaders.Access-Control-Expose-Headers '["X-Stream-Output", "X-Chunked-Output", "X-Content-Length"]'

# Configure the Gateway
ipfs config --json Gateway.APICommands '["get", "dag/get", "cat", "ls", "refs", "refs/local", "resolve", "files/read", "version"]'

# Set localhost as a specifically configured gateway with subdomains disabled
ipfs config --json Gateway.PublicGateways '{
  "localhost": {
    "Paths": ["/ipfs", "/ipns"],
    "UseSubdomains": false
  }
}'

# Start the IPFS daemon 
echo "Starting IPFS daemon..."
exec ipfs daemon --migrate=true