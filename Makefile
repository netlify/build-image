.PHONY: test test-local build-tests build-base run run-local

image = build-image
test-image = $(image)-test

test: build-tests ## Run tests.
	docker run --rm -it \
    $(test-image)


# TODO conditionally build the `$(test-image)` if it doesn't exist
test-local: ## Volume the tests directory and run the tests. Useful while developing locally
	docker run --rm -it \
    -v $(PWD)/tests:/opt/buildhome/test-env/tests:ro \
    -v $(PWD)/run-build.sh:/opt/build-bin/build:ro \
    -v $(PWD)/run-build-functions.sh:/opt/build-bin/run-build-functions.sh:ro \
    $(test-image) \
    --filter "$(FILTER)" --recursive --timing --pretty tests

build-tests: ## Build test image, which includes all the test dependencies and tooling
	docker build \
		-t $(test-image) \
		.

build-base: ## Build base build-image docker image, without test dependencies and tooling
	docker build \
		-t $(image) \
    --target build-image \
		.

run: build-base
	docker run --rm -it \
    $(image)

# TODO conditionally build `$(image)` if it doesn't exist
run-local:
	docker run --rm -it \
    -v $(PWD)/run-build.sh:/opt/build-bin/build:ro \
    -v $(PWD)/run-build-functions.sh:/opt/build-bin/run-build-functions.sh:ro \
    $(image)
