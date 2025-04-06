# IPFS setup

### on your server with public ip
```sh
docker compose up -d
./scripts/test_ipfs.sh
```

if it's allright, continue on your local dev machine

### on your local dev machine
```sh
./scripts/ipfs_setup_server_connection.sh <server_hostname>
docker compose up -d
./scripts/test_ipfs.sh # it may fail on second part, but should work on first
```

and now try local url from server test — it should open at your local machine
