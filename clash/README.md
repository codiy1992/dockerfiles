### Note: You can my Dockerflie below or just pull this image directly using docker command like below   
**`docker run -d --name=clash --net=host --log-opt max-size=10m -e CLASH_SUBSCRIBE_URL=http://xxxxxx/config/docker codiy/clash`**


## 0. Dockerfile  And Supervisor Configuration

```Dockerfile
FROM dreamacro/clash:latest

RUN apk add --no-cache curl supervisor

COPY ./supervisor.d /etc/supervisor.d

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon"]
```

```
[program:clash]
command=/bin/sh -c '
    echo -e '\''#!/bin/sh
    unset http_proxy https_proxy ftp_proxy rsync_proxy all_proxy no_proxy \
          HTTP_PROXY HTTPS_PROXY FTP_PROXY RSYNC_PROXY ALL_PROXY NO_PROXY
    wget -q -O /root/.config/clash/config.yaml -U "ClashForDocker(`/clash -v`)" ${CLASH_SUBSCRIBE_URL}
    curl -sX PUT 127.0.0.1:${CLASH_API_PORT:-9090}/configs?force=true --data-raw '\'\\\'\''{"path": "/root/.config/clash/config.yaml"}'\'\\\'\'' '\'' \
    > /etc/periodic/${CLASH_UPDATE_FREQ:-hourly}/100_update_clash_config; \
    chmod +x /etc/periodic/${CLASH_UPDATE_FREQ:-hourly}/100_update_clash_config; \
    /etc/periodic/${CLASH_UPDATE_FREQ:-hourly}/100_update_clash_config; \
    crond -b; \
    /clash'
process_name=%(program_name)s
numprocs=1
startsecs=15
autostart=true
autorestart=true
priority=1
user=root
umask=0000
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
```

## 1. docker-compose usage example
```yaml
version: '3'

services:
  clash:
    image: codiy/clash:latest
    container_name: clash
    environment:
      - CLASH_SUBSCRIBE_URL=http://xxxxxx/config/docker
    network_mode: host
    logging:
      driver: json-file
      options:
        max-size: 1m
```

##  2. required environment variable

```yaml
environment:
   - CLASH_SUBSCRIBE_URL=http://xxx/config
```

## 3. optional environment variables

```yaml
environment:
  - CLASH_API_PORT=9090
  - CLASH_UPDATE_FREQ=hourly // 15min|hourly|daily|weekly|monthly
```

## 4. (optional) docker proxy configuration
docker will use proxy configuration automatically, when  using `docker build` or in docker container

```shell
LOCAL_IP=$(hostname -i)
echo -e "
{
    "proxies": {
        "default": {
            "httpProxy": "http://${LOCAL_IP}:7890",
            "httpsProxy": "http://${LOCAL_IP}:7890",
            "noProxy": "127.0.0.0/8,10.0.0.0/8,169.254.169.254"
        }
    }
}" > ~/.docker/config.json
```
