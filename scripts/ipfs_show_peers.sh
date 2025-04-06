#!/bin/bash

# Show all connected IPFS peers
curl -s -X POST "http://localhost:5001/api/v0/swarm/peers" | jq -r '.Peers' 