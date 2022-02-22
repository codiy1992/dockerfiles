# Synchthing

## Usage

```yaml
version: "3.7"

services:
  syncthing:
    image: codiy/syncthing
    container_name: syncthing
    hostname: syncthing
    environment:
      - PUID=501
      - PGID=20
    volumes:
      - ${STORAGE_PATH}/syncthing:/var/syncthing
      - ${STORAGE_PATH}/stdiscosrv:/var/stdiscosrv
      - ${STORAGE_PATH}/strelaysrv:/var/strelaysrv
      - ${STORAGE_PATH}/folder_to_sync:/data/foo
    network_mode: host # Use host network to set up UPnP on the router
    # ports:
      # - 8384:8384
      # - 22000:22000/tcp
      # - 22000:22000/udp
      # - 8443:8443
      # - 22067:22067
    restart: always
    logging:
      driver: json-file
      options:
        max-size: 1m
```

## References

* [Source code](https://github.com/codiy1992/dockerfiles/tree/master/syncthing)
* [Dockerfile.synchthing](https://github.com/syncthing/syncthing/blob/main/Dockerfile)
* [Dockerfile.stdiscosrv](https://github.com/syncthing/syncthing/blob/main/Dockerfile.stdiscosrv)
* [Dockerfile.strelaysrv](https://github.com/syncthing/syncthing/blob/main/Dockerfile.strelaysrv)
* [Docs.Syncthing](https://docs.syncthing.net/users/syncthing.html#syncthing)
* [Docs.Stdiscosrv](https://docs.syncthing.net/users/stdiscosrv.html)
* [Docs.Strelaysrv](https://docs.syncthing.net/users/strelaysrv.html)
