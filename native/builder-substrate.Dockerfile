FROM --platform=${TARGETPLATFORM} ubuntu:22.04

## MultiArch Arguments - Required
ARG TARGETARCH
ARG TARGETPLATFORM
ARG RS_NIGHTLY
ARG RS_STABLE
RUN test -n "${RS_NIGHTLY:?}" && \
    test -n "${RS_STABLE:?}" && \
    test -n "${TARGETARCH:?}" && \
    test -n "${TARGETPLATFORM:?}"

## Environment Variables - Build Arguments
ENV RS_NIGHTLY=${RS_NIGHTLY}
ENV RS_STABLE=${RS_STABLE}
ENV TARGETARCH=${TARGETARCH}
ENV TARGETPLATFORM=${TARGETPLATFORM}

## Environment Variables - Static
ENV CARGO_HOME="/usr/local/cargo"
ENV CARGO_INCREMENTAL="false"
ENV CC="clang-15"
ENV CXX="clang-15"
ENV DEBIAN_FRONTEND="noninteractive"
ENV RUSTFLAGS_OPT="-C target-cpu=generic -C opt-level=3 -C codegen-units=1 -C link-args=-s"
ENV RUSTUP_HOME="/usr/local/rustup"
ENV SCCACHE_CACHE_SIZE="32G"
ENV SCCACHE_DIR="/builder/cache"
ENV TZ="Etc/UTC"

## Environment Variables - Dynamic
ENV CARGO_BIN="${CARGO_HOME}/bin"
ENV PATH="${CARGO_BIN}${PATH:+:${PATH}}"
ENV SCCACHE_BIN="${CARGO_BIN}/sccache"
ENV CMAKE_C_COMPILER_LAUNCHER="${SCCACHE_BIN}"
ENV CMAKE_CXX_COMPILER_LAUNCHER="${SCCACHE_BIN}"
ENV RUSTC_WRAPPER="${SCCACHE_BIN}"

## Bases
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    tzdata \
    unzip \
    wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## LLVM 15.x.y
RUN add-apt-repository -y "ppa:ubuntu-toolchain-r/test" && \
    wget -qO- "https://apt.llvm.org/llvm-snapshot.gpg.key" | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc && \
    add-apt-repository -y "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-15 main" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    clang-15 \
    clang-format-15 \
    clang-tidy-15 \
    clang-tools-15 \
    clangd-15 \
    libc++-15-dev \
    libc++-15-dev-wasm32 \
    libc++abi-15-dev \
    libc++abi-15-dev-wasm32 \
    libclang-15-dev \
    libclang-common-15-dev \
    libclang1-15 \
    libclc-15-dev \
    libfuzzer-15-dev \
    libllvm15 \
    libmlir-15-dev \
    libomp-15-dev \
    libunwind-15-dev \
    lld-15 \
    lldb-15 \
    llvm-15 \
    llvm-15-dev \
    llvm-15-runtime \
    mlir-15-tools \
    python3-clang-15 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Others
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    aria2 \
    autoconf \
    automake \
    binaryen \
    binutils-aarch64-linux-gnu \
    binutils-x86-64-linux-gnu \
    build-essential \
    cmake \
    curl \
    dirmngr \
    dpkg-dev \
    emscripten \
    file \
    git \
    git-lfs \
    iputils-arping \
    iputils-clockdiff \
    iputils-ping \
    iputils-tracepath \
    jq \
    libbz2-dev \
    libc6 \
    libc6-dev \
    libc6-dev-amd64-cross \
    libc6-dev-arm64-cross \
    libcurl4-openssl-dev \
    libelf-dev \
    libfuse-dev \
    libfuse3-dev \
    libgpg-error-dev \
    libgpgme-dev \
    liblzma-dev \
    libncurses-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsasl2-dev \
    libsodium-dev \
    libsqlite3-dev \
    libssl-dev \
    libtool \
    libxml2-dev \
    libyaml-dev \
    libzstd-dev \
    make \
    meson \
    nasm \
    netbase \
    ninja-build \
    openssh-client \
    patch \
    pkg-config \
    procps \
    protobuf-compiler \
    python3-dev \
    python3-pip \
    python3-wheel \
    wabt \
    xz-utils \
    yasm \
    zlib1g-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Install Rust & Other utilities
WORKDIR /builder
COPY . .
RUN mv scripts/* ./ && ./install-rust.bash
RUN CPU_ARCH=$(bash -c 'if [[ "${TARGETARCH}" == "amd64" ]]; then echo "x86_64"; else echo "aarch64"; fi'); \
    PREBUILT_DIR="prebuilt/${CPU_ARCH}-unknown-linux-gnu"; \
    cp ${PREBUILT_DIR}/* ${CARGO_BIN}/; \
    ls -Falg && sleep 20; rm -rf *; mkdir cache 

LABEL org.opencontainers.image.authors "Aditya Kresna <kresna@gemtek.id>"
LABEL org.opencontainers.image.source "https://github.com/goro-network/infra-base-images"
LABEL org.opencontainers.image.description "This image is used to build Parity's Substrate based chain for aarch64 & x86_64"
