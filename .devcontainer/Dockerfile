# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

ARG TARGETARCH

FROM scratch AS node-amd64

ADD --checksum=sha256:855d581f8a4eb1a8117e3426de25fe02770592febcfb31369aee1ffbfee9e8ec \
    https://nodejs.org/dist/v24.20.0/node-v24.20.0-linux-x64.tar.gz \
    /tmp/node.tgz

FROM scratch AS node-arm64

ADD --checksum=sha256:3515603e2487879a39bc75716f1a2affd027500c64ba50e845cf72cb33219013 \
    https://nodejs.org/dist/v24.20.0/node-v24.20.0-linux-arm64.tar.gz \
    /tmp/node.tgz

FROM node-${TARGETARCH} AS node

FROM scratch AS go-amd64

ADD --checksum=sha256:63d339f0da5ab53635a56f2490a7984dfe12dfcff22ad749f63edaf590168445 \
    https://dl.google.com/go/go1.27.1.linux-amd64.tar.gz \
    /tmp/go.tgz

FROM scratch AS go-arm64

ADD --checksum=sha256:3450b45a3f9ee8568792736a5c5e70a1f2e9b36c35a8f74958c03e51d7d92bec \
    https://dl.google.com/go/go1.27.1.linux-arm64.tar.gz \
    /tmp/go.tgz

FROM go-${TARGETARCH} AS go

FROM docker.io/library/ubuntu:26.04@sha256:513c074113a871b51a8d16ab445c88779d6452d937a164fb5cc479f32668a41d

COPY --from=node /tmp/node.tgz /tmp/node.tgz
COPY --from=go /tmp/go.tgz /tmp/go.tgz

ENV GOLANG_VERSION=1.27.1
ENV GOTOOLCHAIN=local
ENV GOPATH=/go
ENV NPM_CONFIG_PREFIX=/home/ubuntu/.local
ENV PATH=/home/ubuntu/.local/bin:/go/bin:/usr/local/go/bin:${PATH}

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends ca-certificates gcc git libc6-dev make openssh-client sudo \
    && if [ "$(dpkg --print-architecture)" = arm64 ]; then DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends binutils-gold; fi \
    && tar --extract --gzip --file /tmp/go.tgz --directory /usr/local --no-same-owner \
    && tar --extract --gzip --file /tmp/node.tgz --directory /usr/local --strip-components=1 --no-same-owner --exclude='*/README.md' --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' \
    && ln --symbolic /usr/local/bin/node /usr/local/bin/nodejs \
    && rm --force -- /tmp/go.tgz /tmp/node.tgz \
    && mkdir --parents -- "$GOPATH/src" "$GOPATH/bin" \
    && chmod -R 1777 "$GOPATH" \
    && usermod --shell /bin/bash ubuntu \
    && install --directory --owner ubuntu --group ubuntu \
        /home/ubuntu/.local \
        /home/ubuntu/.local/bin \
        /home/ubuntu/.local/lib \
        /home/ubuntu/.local/lib/node_modules \
    && printf '%s\n' 'ubuntu ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu \
    && rm -rf /var/lib/apt/lists/*

USER ubuntu
