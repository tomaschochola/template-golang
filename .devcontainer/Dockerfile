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

FROM docker.io/library/golang:1.27.1-trixie@sha256:9baa6b4187bbb98d240372a8a235ac0bb6b5ddd52bba1431dc2f7c0705862728

COPY --from=node /tmp/node.tgz /tmp/node.tgz

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends clang git libclang-rt-dev make openssh-client sudo \
    && tar --extract --gzip --file /tmp/node.tgz --directory /usr/local --strip-components=1 --exclude='*/README.md' --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' \
    && rm --force -- /tmp/node.tgz \
    && groupadd --gid 1000 devcontainer \
    && useradd --uid 1000 --gid devcontainer --shell /bin/bash --create-home devcontainer \
    && install --directory --owner devcontainer --group devcontainer \
        /home/devcontainer/.local \
        /home/devcontainer/.local/bin \
        /home/devcontainer/.local/lib \
        /home/devcontainer/.local/lib/node_modules \
    && printf '%s\n' 'devcontainer ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/devcontainer \
    && chmod 0440 /etc/sudoers.d/devcontainer \
    && rm -rf /var/lib/apt/lists/*

ENV NPM_CONFIG_PREFIX=/home/devcontainer/.local
ENV PATH=/home/devcontainer/.local/bin:${PATH}

USER devcontainer
