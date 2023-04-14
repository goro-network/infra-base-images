MAKEFLAGS		+=	--silent --jobs 1
CURRENT_CPU_UNAME	:=	$(shell uname -p)
VER_WORKERS		:=	2.303.0
RS_NIGHTLY		:=	nightly-2023-04-10
RS_STABLE		:=	1.68.2
TAG_PREFIX		:=	ghcr.io/goro-network
TAG_NATIVE_CI		:=	${TAG_PREFIX}/native-ghrunner:${VER_WORKERS}
TAG_NATIVE_BASE		:=	${TAG_PREFIX}/native-base:${RS_STABLE}
ARM_CPU_NAME		:=	aarch64
ARM_CPU_NAME_ALT	:=	arm64
ARM_CPU_LLVM		:=	cortex-a55
ARM_CPU_FEATS		:=	"-C target-feature=+neon,+aes,+sha2,+fp16"
INTEL_CPU_NAME		:=	x86_64
INTEL_CPU_NAME_ALT	:=	x64
INTEL_CPU_LLVM		:=	x86-64
INTEL_CPU_FEATS		:=	"-C target-feature=+aes,+avx2,+cmpxchg16b,+f16c,+fma,+pclmulqdq,+popcnt,+sha,+vaes,+vpclmulqdq"
ifeq (${CURRENT_CPU_UNAME}, ${ARM_CPU_NAME})
CPU_ARCH		:=	${ARM_CPU_NAME}
CPU_ARCH_ALT		:= 	${ARM_CPU_NAME_ALT}
CPU_NAME		:=	${ARM_CPU_LLVM}
CPU_FEATS		:=	${ARM_CPU_FEATS}
else ifeq (${CURRENT_CPU_UNAME}, ${INTEL_CPU_NAME})
CPU_ARCH		:=	${INTEL_CPU_NAME}
CPU_ARCH_ALT		:= 	${INTEL_CPU_NAME_ALT}
CPU_NAME		:=	${INTEL_CPU_LLVM}
CPU_FEATS		:=	${INTEL_CPU_FEATS}
else
$(error Unsupported CPU Target "${CURRENT_CPU_UNAME}")
endif

.PHONY: all check docker-native-base docker-native-ci docker-native-push
.ONESHELL: all check docker-native-base docker-native-ci docker-native-push

all: | docker-native-push

check: | docker-native-base

docker-native-base:
	echo "\033[92mBuilding Docker Image - Base (Substrate Builder) for ${CPU_NAME}\033[0m"
	docker build \
		-t ${TAG_NATIVE_BASE} \
		-f native/builder-substrate.Dockerfile \
		--build-arg CPU_ARCH=${CPU_ARCH} \
		--build-arg CPU_NAME=${CPU_NAME} \
		--build-arg RUSTFLAGS_FEATURES=${CPU_FEATS} \
		--build-arg RUST_VERSION_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RUST_VERSION_STABLE=${RS_STABLE} \
		native/

docker-native-ci: | docker-native-base
	echo "\033[92mBuilding Docker Image - Github Runner (Substrate Builder) for ${CPU_NAME}\033[0m"
	docker build \
		-t ${TAG_NATIVE_CI} \
		-f native/builder-substrate-gh.Dockerfile \
		--build-arg BASE_IMAGE_NAME=${TAG_NATIVE_BASE} \
		--build-arg CPU_ARCH_ALT=${CPU_ARCH_ALT} \
		--build-arg CPU_ARCH=${CPU_ARCH_ALT} \
		--build-arg CPU_NAME=${CPU_NAME} \
		--build-arg RUNNER_VER=${VER_WORKERS} \
		native/

docker-native-push: | docker-native-ci
	echo "\033[92mPushing Docker Images - Substrate Builder for ${CPU_NAME}\033[0m"
	docker push ${TAG_NATIVE_BASE}
	docker push ${TAG_NATIVE_CI}
