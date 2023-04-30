MAKEFLAGS			+=	--jobs 1
RS_NIGHTLY			:=	nightly-2023-03-25
RS_STABLE			:=	1.69.0
VER_WORKERS			:=	2.303.0
BUILDX_BUILDER_NAME		:=	buildx-multiarch-builder
BUILDX_PLATFORM_ARM64		:=	linux/arm64
BUILDX_PLATFORM_AMD64		:=	linux/amd64
BUILDX_PLATFORMS		:=	${BUILDX_PLATFORM_ARM64},${BUILDX_PLATFORM_AMD64}
DOCKERFILE_NATIVE_BASE		:=	native/builder-substrate.Dockerfile
DOCKERFILE_NATIVE_CI		:=	native/builder-substrate-gh.Dockerfile
TAG_PREFIX			:=	ghcr.io/goro-network
TAG_PREFIX_NATIVE_BASE		:=	${TAG_PREFIX}/native-base
TAG_PREFIX_NATIVE_CI		:=	${TAG_PREFIX}/native-ghrunner
TAG_NATIVE_BASE_VERSIONED	:=	${TAG_PREFIX_NATIVE_BASE}:${RS_STABLE}
TAG_NATIVE_BASE_LATEST		:=	${TAG_PREFIX_NATIVE_BASE}:latest
TAG_NATIVE_CI_VERSIONED		:=	${TAG_PREFIX_NATIVE_CI}:${VER_WORKERS}
TAG_NATIVE_CI_LATEST		:=	${TAG_PREFIX_NATIVE_CI}:latest
TAG_NATIVE_BASE_PR		:=	${TAG_PREFIX_NATIVE_BASE}:pr
TAG_NATIVE_CI_PR		:=	${TAG_PREFIX_NATIVE_CI}:pr

.PHONY: all check 
.PHONY: docker-configure-multiarch 
.PHONY: docker-build-native-base-check docker-build-native-ci-check 
.PHONY: docker-build-native-base docker-build-native-ci
.ONESHELL: all check 
.ONESHELL: docker-configure-multiarch 
.ONESHELL: docker-build-native-base-check docker-build-native-ci-check 
.ONESHELL: docker-build-native-base docker-build-native-ci

all: | docker-build-native-ci

check: | docker-build-native-ci-check

docker-configure-multiarch:
	@echo "\033[92m\nInstalling Docker BuildX MultiArch Binary Format...\033[0m"
	@(docker run --privileged --rm tonistiigi/binfmt --install all)
	@echo "\033[92m\nConfiguring Docker BuildX Builder for MultiArch...\033[0m"
	@(docker buildx create --name ${BUILDX_BUILDER_NAME} --driver docker-container --bootstrap --use > /dev/null 2>&1) || true
	@echo "\033[34m\nDocker BuildX Builder for MultiArch Configured ("${BUILDX_BUILDER_NAME}")\033[0m"

docker-build-native-base-check: | docker-configure-multiarch
	@echo "\033[92m\nBuilding Docker Image - Native Base (Pull Request)\033[0m"
	docker build \
		-t ${TAG_NATIVE_BASE_PR} \
		-f ${DOCKERFILE_NATIVE_BASE} \
		--pull \
		--build-arg RS_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RS_STABLE=${RS_STABLE} \
		native/

docker-build-native-ci-check: | docker-build-native-base-check
	@echo "\033[92m\nBuilding Docker Image - Native CI (Pull Request)\033[0m"
	docker build \
		-t ${TAG_NATIVE_CI_PR} \
		-f ${DOCKERFILE_NATIVE_CI} \
		--build-arg BASE_IMAGE_NAME=${TAG_NATIVE_BASE_PR} \
		--build-arg RUNNER_VER=${VER_WORKERS} \
		native/

docker-build-native-base: | docker-configure-multiarch
	@echo "\033[92m\nBuilding Docker Image - Base (Substrate Builder)\033[0m"
	docker buildx build \
		-t ${TAG_NATIVE_BASE_VERSIONED} \
		-f ${DOCKERFILE_NATIVE_BASE} \
		--pull \
		--push \
		--platform ${BUILDX_PLATFORMS} \
		--build-arg RS_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RS_STABLE=${RS_STABLE} \
		native/
	docker buildx build \
		-t ${TAG_NATIVE_BASE_LATEST} \
		-f ${DOCKERFILE_NATIVE_BASE} \
		--pull \
		--push \
		--platform ${BUILDX_PLATFORMS} \
		--build-arg RS_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RS_STABLE=${RS_STABLE} \
		native/

docker-build-native-ci: | docker-build-native-base
	@echo "\033[92m\nBuilding Docker Image - Github Runner (Substrate Builder)\033[0m"
	docker buildx build \
		-t ${TAG_NATIVE_CI_VERSIONED} \
		-f ${DOCKERFILE_NATIVE_CI} \
		--pull \
		--push \
		--platform ${BUILDX_PLATFORMS} \
		--build-arg BASE_IMAGE_NAME=${TAG_NATIVE_BASE_VERSIONED} \
		--build-arg RUNNER_VER=${VER_WORKERS} \
		native/
	docker buildx build \
		-t ${TAG_NATIVE_CI_LATEST} \
		-f ${DOCKERFILE_NATIVE_CI} \
		--pull \
		--push \
		--platform ${BUILDX_PLATFORMS} \
		--build-arg BASE_IMAGE_NAME=${TAG_NATIVE_BASE_LATEST} \
		--build-arg RUNNER_VER=${VER_WORKERS} \
		native/
