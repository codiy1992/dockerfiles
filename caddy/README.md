# Caddy

```Dockerfile
FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/alidns \
    --with github.com/caddy-dns/route53 \
    --with github.com/caddy-dns/cloudflare

FROM caddy

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```
