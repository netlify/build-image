.PHONY: test test-local build-tests build-base run run-local

image = netlify/build
test-image = $(image)-test
arch = $(shell uname -m)

ifneq ($(arch), arm64)
	arch = amd64
endif

test: build-test-image ## Run tests.
	docker run --rm -it \
		$(test-image)

# TODO conditionally build the `$(test-image)` if it doesn't exist
test-local: build-test-image ## Volume the tests directory and build scripts, and run the tests. Useful while developing locally
	docker run --rm -it \
		-v $(PWD)/tests:/opt/buildhome/test-env/tests:ro \
		-v $(PWD)/run-build.sh:/opt/build-bin/build:ro \
		-v $(PWD)/run-build-functions.sh:/opt/build-bin/run-build-functions.sh:ro \
		$(test-image) \
		--filter "$(FILTER)" --recursive --timing --pretty tests

build-test-image: ## Build test image, which includes all the test dependencies and tooling
	docker build \
		--build-arg TARGETARCH=$(arch) \
		-t $(test-image) \
		.

build-base: ## Build base build-image docker image, without test dependencies and tooling
	docker build \
		-t $(image) \
		--build-arg TARGETARCH=$(arch) \
		--target build-image \
		.

run: build-base ## Run a bash shell in the build-image
	docker run --rm -it \
		$(image)

container-test: build-base ## Run a container structure test
	container-structure-test test \
		--image $(image) \
		--config focal.yaml

# TODO conditionally build `$(image)` if it doesn't exist
run-local: build-base ## Volume the build scripts and run a bash shell in the build-image
	docker run --rm -it \
		-e NETLIFY_BUILD_BASE="/opt/buildhome" \
		-v $(PWD)/run-build.sh:/opt/build-bin/build:ro \
		-v $(PWD)/run-build-functions.sh:/opt/build-bin/run-build-functions.sh:ro \
		$(image)
