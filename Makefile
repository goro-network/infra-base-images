MAKEFLAGS	+=	--silent --jobs 1
ARM_CPUS	:=	cortex-a55 cortex-a76 neoverse-n1
TAG_PREFIX	:=	ghcr.io/goro-network
CPU_FEATS	:=	"-C target-feature=+neon,+aes,+sha2,+fp16"
VER_WORKERS	:=	"2.302.1"
BS_IMAGES	:=	$(addprefix native-aarch64-bs-,$(ARM_CPUS))
BS_WORKERS	:=	$(addprefix worker-native-aarch64-bs-,$(ARM_CPUS))
BS_REGISTRY	:=	$(addprefix push-native-aarch64-bs-,$(ARM_CPUS))
RS_NIGHTLY	:=	"nightly-2023-02-10"
RS_STABLE	:=	"1.68.0"

.PHONY: all native-aarch64-bs ${BS_IMAGES} ${BS_WORKER} ${BS_REGISTRY}
.ONESHELL: all native-aarch64-bs ${BS_IMAGES} ${BS_WORKER} ${BS_REGISTRY}

all: | ${BS_WORKERS}

native-aarch64-bs: | ${BS_IMAGES}

worker-native-aarch64-bs: | ${BS_WORKERS}

push-native-aarch64-bs: | ${BS_REGISTRY}

$(BS_IMAGES):
	export CURRENT_CPU="$(strip $(subst native-aarch64-bs-,,$@))"
	export IMAGE_PREFIX="${TAG_PREFIX}/native-aarch64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	echo "\033[92mBuilding Docker Image - Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker build \
		-t $${BS_TAG} \
		-f native/builder-substrate.Dockerfile \
		--build-arg CPU_ARCH="aarch64" \
		--build-arg CPU_NAME=$${CURRENT_CPU} \
		--build-arg RUSTFLAGS_FEATURES=${CPU_FEATS} \
		--build-arg RUST_VERSION_NIGHTLY=${RS_NIGHTLY} \
		--build-arg RUST_VERSION_STABLE=${RS_STABLE} \
		native/

$(BS_WORKERS): | ${BS_IMAGES}
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

$(BS_REGISTRY): | $(BS_WORKERS)
	export CURRENT_CPU=$(strip $(subst push-native-aarch64-bs-,,$@))
	export IMAGE_PREFIX="${TAG_PREFIX}/native-aarch64-$${CURRENT_CPU}"
	export BS_TAG="$${IMAGE_PREFIX}:builder-substrate"
	export CI_TAG="$${IMAGE_PREFIX}:ci-builder-substrate"
	echo "\033[92mPushing Docker Image - Substrate Builder for $${CURRENT_CPU}\033[0m"
	docker push $${BS_TAG}
	docker push $${CI_TAG}
