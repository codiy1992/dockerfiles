# CPUMiner

```yaml
services:
    image: codiy/cpuminer
    container_name: cpuminer
    environment:
      - POOL_URL=${POOL_URL}
      - ALGO=${ALGO}
      - ADDRESS=${BITCOIN_ADDRESS}
      - SERVER_ID=${SERVER_ID}
      - PASSWD=${PASSWD}
      - THREADS=${THREADS}
      - CPU_LIMIT=${CPU_LIMIT}
    restart: unless-stopped
```
