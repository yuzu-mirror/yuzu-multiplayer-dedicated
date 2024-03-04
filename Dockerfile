# syntax=docker/dockerfile:1.3
ARG UBUNTU_RELEASE=23.10
ARG USER=ubuntu UID=101 GROUP=ubuntu GID=101

### BOILERPLATE BEGIN ###

FROM golang:1.20 AS chisel
ARG UBUNTU_RELEASE
RUN git clone -b ubuntu-${UBUNTU_RELEASE} https://github.com/canonical/chisel-releases /opt/chisel-releases \
    && git clone --depth 1 -b main https://github.com/canonical/chisel /opt/chisel
WORKDIR /opt/chisel
RUN go generate internal/deb/version.go \
    && go build ./cmd/chisel

FROM ubuntu:$UBUNTU_RELEASE AS builder
SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
COPY --from=chisel /opt/chisel/chisel /usr/bin/

FROM builder AS rootfs-prep
ARG USER UID GROUP GID
RUN mkdir -p /rootfs/etc \
    && echo "$GROUP:x:$GID:" >/rootfs/etc/group \
    && echo "$USER:x:$UID:$GID::/nohome:/noshell" >/rootfs/etc/passwd

FROM scratch AS image-prep
ARG UID GID
USER $UID:$GID

### BOILERPLATE END ###

FROM ubuntu:$UBUNTU_RELEASE AS build
ENV DEBIAN_FRONTEND=noninteractive
ARG USE_CCACHE
RUN apt-get update && apt-get -y full-upgrade && \
    apt-get install -y build-essential wget git ccache ninja-build libssl-dev pkg-config libarchive-tools \
    cmake cmake-data
COPY . /root/build-files

RUN --mount=type=cache,id=ccache,target=/root/.ccache \
    git clone --depth 1000 -j4 --recursive https://github.com/yuzu-emu/yuzu-mainline.git /root/yuzu-mainline && \
    cd /root/yuzu-mainline && /root/build-files/.ci/build.sh

FROM rootfs-prep AS sliced-deps
COPY --from=chisel /opt/chisel-releases /opt/chisel-releases
RUN chisel cut --release /opt/chisel-releases --root /rootfs \
    base-files_base \
    base-files_release-info \
    ca-certificates_data \
    libgcc-s1_libs \
    libc6_libs \
    libssl3_libs \
    libstdc++6_libs \
    openssl_config \
    openssl_data

FROM image-prep AS final
COPY --from=sliced-deps /rootfs /
LABEL maintainer="yuzuemu"
# Create app directory
WORKDIR /usr/src/app
COPY --from=build /root/yuzu-mainline/build/bin/yuzu-room /usr/src/app
ENTRYPOINT [ "/usr/src/app/yuzu-room" ]
