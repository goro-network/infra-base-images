MAKEFLAGS		+=	--silent --jobs 1
TAG_PREFIX		:=	ghcr.io/goro-network
VER_WORKERS		:=	"2.303.0"
RS_NIGHTLY		:=	"nightly-2023-02-10"
RS_STABLE		:=	"1.68.2"
ARM_CPUS		:=	cortex-a55 cortex-a76 neoverse-n1
ARM_FEATS		:=	"-C target-feature=+neon,+aes,+sha2,+fp16"
ARM_IMAGES		:=	$(addprefix native-aarch64-bs-,$(ARM_CPUS))
ARM_WORKERS		:=	$(addprefix worker-native-aarch64-bs-,$(ARM_CPUS))
ARM_REGISTRY	:=	$(addprefix push-native-aarch64-bs-,$(ARM_CPUS))
INTEL_CPUS		:=	x86-64 sapphirerapids skylake-avx512
INTEL_IMAGES	:=	$(addprefix native-x86_64-bs-,$(INTEL_CPUS))
INTEL_WORKERS	:=	$(addprefix worker-native-x86_64-bs-,$(INTEL_CPUS))
INTEL_REGISTRY	:=	$(addprefix push-native-x86_64-bs-,$(INTEL_CPUS))

.PHONY: native-aarch64-bs ${ARM_IMAGES} ${ARM_WORKERS} ${ARM_REGISTRY} ${INTEL_IMAGES} ${INTEL_WORKERS} ${INTEL_REGISTRY}
.ONESHELL: native-aarch64-bs ${ARM_IMAGES} ${ARM_WORKERS} ${ARM_REGISTRY} ${INTEL_IMAGES} ${INTEL_WORKERS} ${INTEL_REGISTRY}

native-aarch64-bs: | ${ARM_IMAGES}

worker-native-aarch64-bs: | ${ARM_WORKERS}

push-native-aarch64-bs: | ${ARM_REGISTRY}

native-x86_64-bs: | ${INTEL_IMAGES}

worker-native-x86_64-bs: | ${INTEL_WORKERS}

push-native-x86_64-bs: | ${INTEL_REGISTRY}

$(ARM_IMAGES):
	export CURRENT_CPU="$(strip $(subst native-aarch64-bs-,,$@))"
	export IMAGE_PREFIX="${TAG_PREFIX}/native-aarch64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	echo "\033[92mBuilding Docker Image - Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker build \
		-t $${BS_TAG} \
		-f native/builder-substrate.Dockerfile \
		--build-arg CPU_ARCH="aarch64" \
		--build-arg CPU_NAME=$${CURRENT_CPU} \
		--build-arg RUSTFLAGS_FEATURES=${ARM_FEATS} \
		--build-arg RUST_VERSION_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RUST_VERSION_STABLE=${RS_STABLE} \
		native/

$(ARM_WORKERS): | ${ARM_IMAGES}
	export CURRENT_CPU="$(strip $(subst worker-native-aarch64-bs-,,$@))"
	export IMAGE_PREFIX="${TAG_PREFIX}/native-aarch64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	export CI_TAG="$${IMAGE_PREFIX}:ci-builder-substrate"
	echo "\033[92mBuilding Docker Image - CI Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker build \
		-t $${CI_TAG} \
		-f native/builder-substrate-gh.Dockerfile \
		--build-arg BASE_IMAGE_NAME=$${BS_TAG} \
		--build-arg CPU_ARCH_ALT="arm64" \
		--build-arg CPU_ARCH="aarch64" \
		--build-arg CPU_NAME=$${CURRENT_CPU} \
		--build-arg RUNNER_VER=${VER_WORKERS} \
		native/

$(ARM_REGISTRY): | $(ARM_WORKERS)
	export CURRENT_CPU=$(strip $(subst push-native-aarch64-bs-,,$@))
	export IMAGE_PREFIX="${TAG_PREFIX}/native-aarch64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	export CI_TAG="$${IMAGE_PREFIX}:ci-builder-substrate"
	echo "\033[92mPushing Docker Image - Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker push $${BS_TAG}
	docker push $${CI_TAG}

$(INTEL_IMAGES):
	export CURRENT_CPU="$(strip $(subst native-x86_64-bs-,,$@))"
	export IMAGE_PREFIX="${TAG_PREFIX}/native-x86_64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	echo "\033[92mBuilding Docker Image - Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker build \
		-t $${BS_TAG} \
		-f native/builder-substrate.Dockerfile \
		--build-arg CPU_ARCH="x86_64" \
		--build-arg CPU_NAME=$${CURRENT_CPU} \
		--build-arg RUSTFLAGS_FEATURES=${INTEL_FEATS} \
		--build-arg RUST_VERSION_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RUST_VERSION_STABLE=${RS_STABLE} \
		native/

$(INTEL_WORKERS): | ${INTEL_IMAGES}
	export CURRENT_CPU="$(strip $(subst worker-native-x86_64-bs-,,$@))"
	export IMAGE_PREFIX="${TAG_PREFIX}/native-x86_64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	export CI_TAG="$${IMAGE_PREFIX}:ci-builder-substrate"
	echo "\033[92mBuilding Docker Image - CI Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker build \
		-t $${CI_TAG} \
		-f native/builder-substrate-gh.Dockerfile \
		--build-arg BASE_IMAGE_NAME=$${BS_TAG} \
		--build-arg CPU_ARCH_ALT="x64" \
		--build-arg CPU_ARCH="x86_64" \
		--build-arg CPU_NAME=$${CURRENT_CPU} \
		--build-arg RUNNER_VER=${VER_WORKERS} \
		native/

$(INTEL_REGISTRY): | $(INTEL_WORKERS)
	export CURRENT_CPU=$(strip $(subst push-native-x86_64-bs-,,$@))
	export IMAGE_PREFIX="${TAG_PREFIX}/native-x86_64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	export CI_TAG="$${IMAGE_PREFIX}:ci-builder-substrate"
	echo "\033[92mPushing Docker Image - Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker push $${BS_TAG}
	docker push $${CI_TAG}
