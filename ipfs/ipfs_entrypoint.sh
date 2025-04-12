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

# Configure Gateway to make content accessible without subdomain redirects
ipfs config --json Gateway '{
  "HTTPHeaders": {
    "Access-Control-Allow-Headers": ["X-Requested-With", "Range", "User-Agent", "Origin", "Content-Type"],
    "Access-Control-Allow-Methods": ["GET", "HEAD", "OPTIONS"],
    "Access-Control-Allow-Origin": ["*"]
  },
  "RootRedirect": "",
  "Writable": false,
  "NoDNSLink": true,
  "PublicGateways": {
    "localhost": {
      "Paths": ["/ipfs", "/ipns"],
      "UseSubdomains": false
    }
  }
}'

# Configure Swarm for better connectivity
echo "Configuring Swarm for network connectivity..."
# Configure Swarm to listen on all interfaces
ipfs config --json Addresses.Swarm '["/ip4/0.0.0.0/tcp/4001", "/ip4/0.0.0.0/udp/4001/quic-v1", "/ip6/::/tcp/4001", "/ip6/::/udp/4001/quic-v1"]'

# Enable hole punching for NAT traversal
ipfs config --json Swarm.EnableHolePunching true

# Configure address filters to block private IP ranges
echo "Configuring address filters to prevent scanning private networks..."
ipfs config --json Swarm.AddrFilters '[
  "/ip4/10.0.0.0/ipcidr/8",
  "/ip4/172.16.0.0/ipcidr/12",
  "/ip4/192.168.0.0/ipcidr/16",
  "/ip4/100.64.0.0/ipcidr/10",
  "/ip4/169.254.0.0/ipcidr/16",
  "/ip4/192.0.0.0/ipcidr/24",
  "/ip4/192.0.2.0/ipcidr/24",
  "/ip4/198.18.0.0/ipcidr/15",
  "/ip4/198.51.100.0/ipcidr/24",
  "/ip4/203.0.113.0/ipcidr/24",
  "/ip4/240.0.0.0/ipcidr/4"
]'

# Configure connection manager for better performance
ipfs config --json Swarm.ConnMgr '{
  "Type": "basic",
  "LowWater": 100,
  "HighWater": 400,
  "GracePeriod": "20s"
}'

# Enable automatic relay client for NAT traversal
echo "Enabling automatic relay client..."
ipfs config --json Swarm.RelayClient.Enabled true
ipfs config --json Swarm.RelayClient.StaticRelays '[]' # Keep empty unless specific relays are needed

# Disable automatic relay service
echo "Disabling automatic relay service..."
ipfs config --json Swarm.RelayService.Enabled false

# Configure AutoNAT service for reachability discovery
echo "Setting AutoNAT service mode to 'enabled'..."
ipfs config --json AutoNAT.ServiceMode '"enabled"'

# Reset bootstrap nodes to ensure we're using the latest ones
echo "Resetting bootstrap nodes..."
ipfs bootstrap rm --all
ipfs bootstrap add --default

# Add servers from IPFS_SERVERS environment variable
if [ ! -z "$IPFS_SERVERS" ]; then
  echo "Adding servers from IPFS_SERVERS list..."
  
  # Split the comma-separated string
  IFS=','
  for server_entry in $IPFS_SERVERS; do
    # Extract hostname and peer ID
    HOSTNAME=$(echo $server_entry | cut -d':' -f1)
    PEER_ID=$(echo $server_entry | cut -d':' -f2)
    
    if [ ! -z "$HOSTNAME" ] && [ ! -z "$PEER_ID" ]; then
      echo "Adding server $HOSTNAME with peer ID $PEER_ID to bootstrap list"
      MULTIADDR="/dns4/$HOSTNAME/tcp/4001/p2p/$PEER_ID"
      ipfs bootstrap add "$MULTIADDR"
    fi
  done
  unset IFS
fi

# Start the IPFS daemon with connection options
echo "Starting IPFS daemon..."
exec ipfs daemon --migrate=true --enable-gc --routing=dht