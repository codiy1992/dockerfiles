FROM rust:latest as builder

WORKDIR /usr/src/anki-sync-server-rs

RUN git clone https://github.com/ankicommunity/anki-sync-server-rs.git .

RUN cargo build --release

FROM debian:stable-slim as runner

COPY --from=builder /usr/src/anki-sync-server-rs/target/release/ankisyncd /usr/local/bin/ankisyncd

RUN chmod +x /usr/local/bin/ankisyncd

CMD ["ankisyncd"]
