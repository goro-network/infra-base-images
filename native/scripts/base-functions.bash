#!/bin/bash

function setenv_with_arm64_or_amd64() {
    if [ ${TARGETARCH} == arm64 ]; then
        export ${1}="${2}"
    elif [ ${TARGETARCH} == amd64 ]; then
        export ${1}="${3}"
    else
        echo -e "\033[31mInvalid TargetPlatform => ${TARGETPLATFORM}\033[0m" 
        exit 1
    fi
}

function setenv_rustflags() {
    setenv_with_arm64_or_amd64 \
        RUSTFLAGS_FEATS \
        "-C target-feature=+neon,+aes,+sha2,+fp16" \
        "-C target-feature=+aes,+avx2,+f16c,+fma,+pclmulqdq,+popcnt"
    export RUSTFLAGS="${RUSTFLAGS_OPT} ${RUSTFLAGS_FEATS}"
}
