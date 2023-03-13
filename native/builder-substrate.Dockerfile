FROM ubuntu:22.04

## Environment Variables
ENV CARGO_HOME="/usr/local/cargo"
ENV CARGO_BIN="${CARGO_HOME}/bin"
ENV CARGO_INCREMENTAL="false"
ENV CC="clang-15"
ENV CXX="clang-15"
ENV DEBIAN_FRONTEND="noninteractive"
ENV PATH="${CARGO_BIN}${PATH:+:${PATH}}"
ENV RUSTUP_HOME="/usr/local/rustup"
ENV TZ="Etc/UTC"

## Bases
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    aria2 \
    autoconf \
    automake \
    binaryen \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    dirmngr \
    dpkg-dev \
    emscripten \
    file \
    git \
    git-lfs \
    gnupg \
    iputils-arping \
    iputils-clockdiff \
    iputils-ping \
    iputils-tracepath \
    libbz2-dev \
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
    lsb-release \
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
    software-properties-common \
    tzdata \
    unzip \
    wabt \
    wget \
    xz-utils \
    yasm \
    zlib1g-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## LLVM 14.0.0-1ubuntu1
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    clang \
    clang-format \
    clang-tidy \
    clangd \
    libc++-dev \
    libc++abi-dev \
    libclang-cpp-dev \
    libclang-dev \
    libclc-dev \
    libclc-ptx \
    libllvm-ocaml-dev \
    libomp-dev \
    lld \
    lldb \
    llvm \
    llvm-dev \
    llvm-runtime \
    python3-clang && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## LLVM 15.0.7
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 15 all && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm llvm.sh

## Build Args - Required
ARG CPU_ARCH
ARG CPU_NAME
ARG RUST_VERSION_NIGHTLY
ARG RUST_VERSION_STABLE
RUN test -n "${CPU_ARCH:?}" && \
    test -n "${CPU_NAME:?}" && \
    test -n "${RUST_VERSION_NIGHTLY:?}" && \
    test -n "${RUST_VERSION_STABLE:?}"

## Build Args - Optional
ARG RUSTFLAGS_FEATURES
ARG RUST_HOST="${CPU_ARCH}-unknown-linux-gnu"
ARG RUSTFLAGS_OPTIMIZATIONS="-C opt-level=3 -C codegen-units=1 -C link-args=-s"
ARG RUSTFLAGS_CPU="-C target-cpu=${CPU_NAME}"
ARG RUSTFLAGS="${RUSTFLAGS_OPTIMIZATIONS} ${RUSTFLAGS_CPU} ${RUSTFLAGS_FEATURES}"
ARG WASMTIME_VERSION="6.0.1"

## Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- \
    -y \
    --default-host ${RUST_HOST} \
    --default-toolchain ${RUST_VERSION_NIGHTLY} \
    --profile minimal \
    --component clippy rust-src rustfmt \
    --target wasm32-unknown-unknown wasm32-unknown-emscripten wasm32-wasi && \
    rustup toolchain install ${RUST_VERSION_STABLE} \
    --profile minimal \
    --component clippy rust-src rustfmt \
    --target wasm32-unknown-unknown wasm32-unknown-emscripten wasm32-wasi && \
    ln -s /usr/local/rustup/toolchains/${RUST_VERSION_NIGHTLY}-${RUST_HOST} \
    /usr/local/rustup/toolchains/nightly-${RUST_HOST} && \
    ln -s /usr/local/rustup/toolchains/${RUST_VERSION_STABLE}-${RUST_HOST} \
    /usr/local/rustup/toolchains/stable-${RUST_HOST}

## Build Utils (https://github.com/mozilla/sccache)
RUN cargo install sccache --no-default-features

## Build Utils (Others)
WORKDIR /builder/cache
WORKDIR /builder
ENV SCCACHE_BIN="${CARGO_BIN}/sccache"
ENV CMAKE_C_COMPILER_LAUNCHER="${SCCACHE_BIN}"
ENV CMAKE_CXX_COMPILER_LAUNCHER="${SCCACHE_BIN}"
ENV RUSTC_WRAPPER="${SCCACHE_BIN}"
ENV SCCACHE_CACHE_SIZE="32G"
ENV SCCACHE_DIR="/builder/cache"
RUN >&2 echo "Building builder utilities with \"${RUSTFLAGS}\""
RUN cargo install --locked \
    cargo-chef \
    cargo-deny \
    cargo-dylint \
    cargo-hack \
    cargo-nextest \
    cargo-spellcheck \
    cargo-udeps \
    cargo-web \
    dylint-link \
    wasm-gc \
    wasm-pack && \
    cargo install --version 0.2.84 wasm-bindgen-cli && \
    cargo install --locked websocat --features="seqpacket crypto_peer prometheus_peer" && \
    cargo install --locked wasmtime-cli --features="pooling-allocator component-model" && \
    cargo install --locked --git https://github.com/paritytech/diener --rev c201fa1 && \
    cargo install --locked --git https://github.com/chevdor/subwasm --tag v0.19.0 && \
    cargo install --locked cargo-contract && \
    rm -rf ${CARGO_HOME}/registry ${CARGO_HOME}/git ${SCCACHE_DIR} && \
    rustup toolchain remove nightly-2022-06-30 && \
    mkdir ${SCCACHE_DIR}

## Print Toolchain Info
RUN echo "\n** Rust **" && \
    >&2 rustc -vV && \
    >&2 rustup show && \
    >&2 sccache --version && \
    echo "\n** GCC **" && \
    gcc -v && \
    echo "\n** LLVM **" && \
    clang -v && echo ""

LABEL maintainer "Aditya Kresna <kresna@gemtek.id>"
LABEL org.opencontainers.image.source "https://github.com/goro-network/infra-base-images"
LABEL org.opencontainers.image.description "This image is used to build Parity's Substrate based chain for ${CPU_ARCH}-${CPU_NAME}"
