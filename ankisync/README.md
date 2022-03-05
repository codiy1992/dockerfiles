# anki-sync-server

## Configuration

```
[address]
host="0.0.0.0"
port = "27701"

[paths]
root_dir="/data"
# data_root = "/data/collections"
# auth_db_path = "/data/auth.db"
# session_db_path = "/data/session.db"

[account]
username="codiy"
password="WhatTheFuck"

[localcert]
ssl_enable=false
cert_file=""
key_file=""
```

## Usage (docker-compose)

```
version: "3.8"

services:
  ankisync:
    image: codiy/ankisync
    container_name: ankisync
    hostname: ankisync
    working_dir: /ankisync
    volumes:
      - ${PWD}/ankisync/settings.toml:/ankisync/Settings.toml
      - ${STORAGE_PATH}/ankisync:/data
    ports:
      - 27701:27701
```

## References

* [anki-sync-server-rs](https://github.com/ankicommunity/anki-sync-server-rs)
