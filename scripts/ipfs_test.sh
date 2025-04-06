#!/bin/bash

# Create tmp directory if it doesn't exist
mkdir -p tmp

# Generate a random filename
RANDOM_NAME=$(openssl rand -hex 5)
FILE_PATH="tmp/${RANDOM_NAME}.txt"

# Get current UTC time
CURRENT_UTC=$(date -u "+%Y-%m-%d %H:%M:%S UTC")

# Generate random content (macOS compatible)
RANDOM_CONTENT=$(openssl rand -base64 512 | fold -w 80 | head -n 15)

# Write content to file with UTC timestamp at the top
echo "Creating random test file: $FILE_PATH"
echo "File created on: $CURRENT_UTC" > "$FILE_PATH"
echo "" >> "$FILE_PATH"
echo "$RANDOM_CONTENT" >> "$FILE_PATH"
echo "File created with $(wc -c < "$FILE_PATH") bytes"

# Add the file to IPFS
echo "Adding file to IPFS..."
IPFS_RESULT=$(curl -s -X POST -F "file=@$FILE_PATH" "http://localhost:5001/api/v0/add")
CID=$(echo $IPFS_RESULT | grep -o '"Hash":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CID" ]; then
    echo "Failed to get CID from IPFS response: $IPFS_RESULT"
    exit 1
fi

echo "File added to IPFS with CID: $CID"

# Test local gateway
LOCAL_URL="http://localhost:8080/ipfs/$CID"
echo "Testing local gateway..."
echo "Browser URL: $LOCAL_URL"
echo "Testing with curl..."
CURL_RESULT=$(curl -s -o /dev/null -w "%{http_code}" "$LOCAL_URL")

if [ "$CURL_RESULT" == "200" ]; then
    echo "✅ Local gateway test passed!"
    echo "Content preview:"
    curl -s "$LOCAL_URL" | head -n 5
else
    echo "❌ Local gateway test failed with status: $CURL_RESULT"
fi

# Test public gateway
echo -e "\nTesting public gateway..."
# Public gateways options: ipfs.io, dweb.link, cf-ipfs.com
PUBLIC_GATEWAY="https://ipfs.io"
PUBLIC_URL="$PUBLIC_GATEWAY/ipfs/$CID"
echo "Browser URL: $PUBLIC_URL"
echo "Testing with curl (may take some time to propagate)..."
CURL_RESULT=$(curl -s -o /dev/null -w "%{http_code}" "$PUBLIC_URL")

if [ "$CURL_RESULT" == "200" ]; then
    echo "✅ Public gateway test passed!"
    echo "Content preview:"
    curl -s "$PUBLIC_URL" | head -n 5
else
    echo "❌ Public gateway test failed with status: $CURL_RESULT"
    echo "This is normal if the content hasn't propagated to the public gateway yet."
    echo "Try opening the URL in a browser after a few moments."
fi

echo -e "\nTest completed. Access your file with these URLs:"
echo "Local: $LOCAL_URL"
echo "Public: $PUBLIC_URL" 