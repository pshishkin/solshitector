#!/bin/bash

# This script discovers an IPFS peer ID from a remote host and suggests how to update your .env file

# Get hostname from argument or prompt for it
if [ -z "$1" ]; then
    read -p "Enter remote hostname with IPFS node: " HOSTNAME
else
    HOSTNAME="$1"
fi

echo "Connecting to $HOSTNAME to discover IPFS peer ID..."

# Check SSH connection
ssh -q -o BatchMode=yes -o ConnectTimeout=5 $HOSTNAME exit
if [ $? -ne 0 ]; then
    echo "❌ Cannot connect to $HOSTNAME via SSH. Please check your SSH configuration."
    exit 1
fi

# Get server's peer ID
echo "Getting IPFS peer ID from $HOSTNAME..."
SERVER_INFO=$(ssh $HOSTNAME 'curl -s -X POST "http://localhost:5001/api/v0/id"')
if [ $? -ne 0 ]; then
    echo "❌ Failed to retrieve IPFS peer ID. Is IPFS running on $HOSTNAME?"
    exit 1
fi

SERVER_PEER_ID=$(echo $SERVER_INFO | jq -r '.ID')

if [ -z "$SERVER_PEER_ID" ] || [ "$SERVER_PEER_ID" == "null" ]; then
    echo "❌ Failed to parse IPFS peer ID from response."
    echo "Raw response: $SERVER_INFO"
    exit 1
fi

echo "✅ Found IPFS peer ID: $SERVER_PEER_ID"

# Check if .env exists and read current config
ENV_FILE="./.env"
EXISTING_SERVERS=""
if [ -f "$ENV_FILE" ] && grep -q "IPFS_SERVERS=" "$ENV_FILE"; then
    EXISTING_SERVERS=$(grep "IPFS_SERVERS=" "$ENV_FILE" | cut -d'"' -f2)
fi

# Check if this server is already in the list
if echo "$EXISTING_SERVERS" | grep -q "$HOSTNAME:"; then
    echo "NOTE: Server $HOSTNAME is already in your IPFS_SERVERS list."
    echo "You may want to update its peer ID."
    
    # Show how to remove the existing entry
    echo -e "\nTo remove the existing entry, edit .env and modify IPFS_SERVERS to remove: $HOSTNAME:<old-peer-id>"
fi

# Format new server entry
NEW_SERVER_ENTRY="$HOSTNAME:$SERVER_PEER_ID"

# Create suggestion for the new .env entry
if [ -z "$EXISTING_SERVERS" ]; then
    SUGGESTED_SERVERS="$NEW_SERVER_ENTRY"
else
    # Add if not already in list
    if ! echo "$EXISTING_SERVERS" | grep -q "$HOSTNAME:$SERVER_PEER_ID"; then
        SUGGESTED_SERVERS="$EXISTING_SERVERS,$NEW_SERVER_ENTRY"
    else
        SUGGESTED_SERVERS="$EXISTING_SERVERS"
        echo "This exact server entry is already in your IPFS_SERVERS list."
    fi
fi

# Display suggestions
echo -e "\n========== ADD THIS TO YOUR .env FILE ==========\n"
echo "IPFS_SERVERS=\"$SUGGESTED_SERVERS\""
echo -e "\n================================================\n"
echo "After adding this to your .env file, restart your IPFS container with:"
echo "docker compose down && docker compose up -d"
