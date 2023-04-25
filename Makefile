MAKEFLAGS			+=	--silent --jobs 1
CURRENT_CPU_UNAME		:=	$(shell uname -p)
VER_WORKERS			:=	2.303.0
RS_NIGHTLY			:=	nightly-2023-04-23
RS_STABLE			:=	1.69.0
ARM_CPU_NAME			:=	aarch64
ARM_CPU_NAME_ALT		:=	arm64
ARM_CPU_NAME_TAG		:=	arm64
ARM_CPU_LLVM			:=	cortex-a55
ARM_CPU_FEATS			:=	"-C target-feature=+neon,+aes,+sha2,+fp16"
INTEL_CPU_NAME			:=	x86_64
INTEL_CPU_NAME_ALT		:=	x64
INTEL_CPU_NAME_TAG		:=	amd64
INTEL_CPU_LLVM			:=	x86-64
INTEL_CPU_FEATS			:=	"-C target-feature=+aes,+avx2,+f16c,+fma,+pclmulqdq,+popcnt"
ifeq (${CURRENT_CPU_UNAME}, ${ARM_CPU_NAME})
CPU_ARCH			:=	${ARM_CPU_NAME}
CPU_ARCH_ALT			:= 	${ARM_CPU_NAME_ALT}
CPU_ARCH_TAG			:=	${ARM_CPU_NAME_TAG}
CPU_NAME			:=	${ARM_CPU_LLVM}
CPU_FEATS			:=	${ARM_CPU_FEATS}
else ifeq (${CURRENT_CPU_UNAME}, ${INTEL_CPU_NAME})
CPU_ARCH			:=	${INTEL_CPU_NAME}
CPU_ARCH_ALT			:= 	${INTEL_CPU_NAME_ALT}
CPU_ARCH_TAG			:=	${INTEL_CPU_NAME_TAG}
CPU_NAME			:=	${INTEL_CPU_LLVM}
CPU_FEATS			:=	${INTEL_CPU_FEATS}
else
$(error Unsupported CPU Target "${CURRENT_CPU_UNAME}")
endif
CPU_PLATFORM			:=	linux/${CPU_ARCH_TAG}
TAG_PREFIX			:=	ghcr.io/goro-network
TAG_PREFIX_NATIVE_BASE		:=	${TAG_PREFIX}/native-base
TAG_PREFIX_NATIVE_CI		:=	${TAG_PREFIX}/native-ghrunner
TAG_NATIVE_BASE			:=	${TAG_PREFIX_NATIVE_BASE}:${RS_STABLE}-${CPU_ARCH_TAG}
TAG_NATIVE_BASE_LATEST		:=	${TAG_PREFIX_NATIVE_BASE}:latest-${CPU_ARCH_TAG}
TAG_NATIVE_CI			:=	${TAG_PREFIX_NATIVE_CI}:${VER_WORKERS}-${CPU_ARCH_TAG}
TAG_NATIVE_CI_LATEST		:=	${TAG_PREFIX_NATIVE_CI}:latest-${CPU_ARCH_TAG}
TAG_NATIVE_BASE_ARM64_VERSIONED	:=	${TAG_PREFIX_NATIVE_BASE}:${RS_STABLE}-${ARM_CPU_NAME_TAG}
TAG_NATIVE_BASE_ARM64_LATEST	:=	${TAG_PREFIX_NATIVE_BASE}:latest-${ARM_CPU_NAME_TAG}
TAG_NATIVE_BASE_AMD64_VERSIONED	:=	${TAG_PREFIX_NATIVE_BASE}:${RS_STABLE}-${INTEL_CPU_NAME_TAG}
TAG_NATIVE_BASE_AMD64_LATEST	:=	${TAG_PREFIX_NATIVE_BASE}:latest-${INTEL_CPU_NAME_TAG}
TAG_NATIVE_BASE_VERSIONED	:=	${TAG_PREFIX_NATIVE_BASE}:${RS_STABLE}
TAG_NATIVE_BASE_LATEST		:=	${TAG_PREFIX_NATIVE_BASE}:latest
TAG_NATIVE_CI_ARM64_VERSIONED	:=	${TAG_PREFIX_NATIVE_CI}:${VER_WORKERS}-${ARM_CPU_NAME_TAG}
TAG_NATIVE_CI_ARM64_LATEST	:=	${TAG_PREFIX_NATIVE_CI}:latest-${ARM_CPU_NAME_TAG}
TAG_NATIVE_CI_AMD64_VERSIONED	:=	${TAG_PREFIX_NATIVE_CI}:${VER_WORKERS}-${INTEL_CPU_NAME_TAG}
TAG_NATIVE_CI_AMD64_LATEST	:=	${TAG_PREFIX_NATIVE_CI}:latest-${INTEL_CPU_NAME_TAG}
TAG_NATIVE_CI_VERSIONED		:=	${TAG_PREFIX_NATIVE_CI}:${VER_WORKERS}
TAG_NATIVE_CI_LATEST		:=	${TAG_PREFIX_NATIVE_CI}:latest

.PHONY: all check docker-native-base docker-native-ci docker-native-push docker-native-manifest
.ONESHELL: all check docker-native-base docker-native-ci docker-native-push docker-native-manifest

all: | docker-native-push

check: | docker-native-base

manifest: | docker-native-manifest

docker-native-base:
	echo "\033[92mCPU Instructions for ${CPU_NAME}\033[0m"
	echo "***"
	lscpu | grep -i "flags"
	echo "***"
	echo "\033[92mBuilding Docker Image - Base (Substrate Builder) for ${CPU_NAME}\033[0m"
	docker buildx build \
		-t ${TAG_NATIVE_BASE} \
		-f native/builder-substrate.Dockerfile \
		--pull \
		--progress plain \
		--platform ${CPU_PLATFORM} \
		--build-arg CPU_ARCH=${CPU_ARCH} \
		--build-arg CPU_NAME=${CPU_NAME} \
		--build-arg RUSTFLAGS_FEATURES=${CPU_FEATS} \
		--build-arg RUST_VERSION_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RUST_VERSION_STABLE=${RS_STABLE} \
		native/
	docker tag ${TAG_NATIVE_BASE} ${TAG_NATIVE_BASE_LATEST}

docker-native-ci: | docker-native-base
	echo "\033[92mBuilding Docker Image - Github Runner (Substrate Builder) for ${CPU_NAME}\033[0m"
	docker buildx build \
		-t ${TAG_NATIVE_CI} \
		-f native/builder-substrate-gh.Dockerfile \
		--pull \
		--progress plain \
		--platform ${CPU_PLATFORM} \
		--build-arg BASE_IMAGE_NAME=${TAG_NATIVE_BASE} \
		--build-arg CPU_ARCH_ALT=${CPU_ARCH_ALT} \
		--build-arg CPU_ARCH=${CPU_ARCH_ALT} \
		--build-arg CPU_NAME=${CPU_NAME} \
		--build-arg RUNNER_VER=${VER_WORKERS} \
		native/
	docker tag ${TAG_NATIVE_CI} ${TAG_NATIVE_CI_LATEST}

docker-native-push: | docker-native-ci
	echo "\033[92mPushing Docker Images - Substrate Builder for ${CPU_NAME}\033[0m"
	docker push ${TAG_NATIVE_BASE}
	docker push ${TAG_NATIVE_BASE_LATEST}
	docker push ${TAG_NATIVE_CI}
	docker push ${TAG_NATIVE_CI_LATEST}

docker-native-manifest:
	echo "\033[92mPushing Docker Manifest - Base (Substrate Builder) for aarch64 & x86_64\033[0m"
	docker pull ${TAG_NATIVE_BASE_ARM64_VERSIONED}
	docker pull ${TAG_NATIVE_BASE_ARM64_LATEST}
	docker pull ${TAG_NATIVE_BASE_AMD64_VERSIONED}
	docker pull ${TAG_NATIVE_BASE_AMD64_LATEST}
	docker manifest create \
		--amend \
		${TAG_NATIVE_BASE_VERSIONED} \
		${TAG_NATIVE_BASE_ARM64_VERSIONED} \
		${TAG_NATIVE_BASE_AMD64_VERSIONED}
	docker manifest create \
		--amend \
		${TAG_NATIVE_BASE_LATEST} \
		${TAG_NATIVE_BASE_ARM64_LATEST} \
		${TAG_NATIVE_BASE_AMD64_LATEST}
	docker manifest push ${TAG_NATIVE_BASE_VERSIONED}
	docker manifest push ${TAG_NATIVE_BASE_LATEST}
	echo "\033[92mPushing Docker Manifest - Github Runner (Substrate Builder) for aarch64 & x86_64\033[0m"
	docker pull ${TAG_NATIVE_CI_ARM64_VERSIONED}
	docker pull ${TAG_NATIVE_CI_ARM64_LATEST}
	docker pull ${TAG_NATIVE_CI_AMD64_VERSIONED}
	docker pull ${TAG_NATIVE_CI_AMD64_LATEST}
	docker manifest create \
		--amend \
		${TAG_NATIVE_CI_VERSIONED} \
		${TAG_NATIVE_CI_ARM64_VERSIONED} \
		${TAG_NATIVE_CI_AMD64_VERSIONED}
	docker manifest create \
		--amend \
		${TAG_NATIVE_CI_LATEST} \
		${TAG_NATIVE_CI_ARM64_LATEST} \
		${TAG_NATIVE_CI_AMD64_LATEST}
	docker manifest push ${TAG_NATIVE_CI_VERSIONED}
	docker manifest push ${TAG_NATIVE_CI_LATEST}
