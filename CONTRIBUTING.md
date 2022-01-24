# CONTRIBUTING

Contributions are always welcome, no matter how large or small. Before contributing,
please read the [code of conduct](CODE_OF_CONDUCT.md).

## Development

### Linting

[ShellCheck](https://github.com/koalaman/shellcheck) usage is recommended, however it is not enforced.

### Tests

We have a set of automated tests in [./tests](./tests). These are [bats](https://github.com/bats-core/bats-core) tests that we use to make assertions not only on the correct functioning of our bash/shell scripts, but also of the software provided by our Docker image. Any fix or feature should be accompanied by a set of tests to validate that those changes work as expected. For an overview on how [bats works see here](https://bats-core.readthedocs.io/en/stable/).

### Developing

We provide a [Makefile](./Makefile) with a set of utility targets to help with development.

Some examples:

- `make test` build the test docker image and run the tests in [TAP fromat](http://testanything.org/).
- `make test-local` creates a volume of the tests directory and the build scripts and run the tests inside the container. Useful when developing locally.
- `make test-local FILTER=<regex>` provide a filter regex string to your test execution in order to select a specific set of tests.
- `make run` build the base image and run a bash shell in a container based in it in interactive mode.
- `make run-local` volume the build scripts and run a bash shell in a container based in the build image.

Our [changelog](./CHANGELOG.md) is powered by an automated [release-please](https://github.com/googleapis/release-please) action, which relies on commits following the [conventional commit format](https://www.conventionalcommits.org/en/v1.0.0-beta.2/#summary).
For the CI validation to succeed, make sure that **your PRs and commits follow the conventional commits format**.

### CI

The bulk of our CI work takes place in [Circle CI](https://app.circleci.com/pipelines/github/netlify/build-image).

If **you're part of the Netlify org** and have write access to the repo, our pipeline will take care of:
- Linting the Dockerfile
- Build your Dockerfile, tag it, and push it to our [docker hub repo](https://hub.docker.com/r/netlify/build)
- Run the automated [bats tests](#tests)


If you **don't have write access to the repo** and are submitting a PR via a forked repo, the CI pipeline will still execute for you. The main difference is that it won't push your built image to our docker repo.
If required, someone with write accesss to the repo can trigger the push for you. If you require it (mainly useful for testing purposes) reach out to someone on the team :+1:

## Releasing

1. Create two PRs, one branching off `focal` and one branching off `xenial`, with your changes applied to each.
2. Once the PRs are approved, merge them into their respective base branches. The merge commit should also follow the [conventional commit format](https://www.conventionalcommits.org/en/v1.0.0-beta.2/#summary).
3. Commits which are prefaced withb `fix:` or `feat:` will trigger package release PRs created by [release-please](https://github.com/googleapis/release-please). Merge these PRs. If you need to manually trigger a release-please PR you can bump the version by creating an [empty PR](https://github.com/netlify/build-image/pull/728).
4. Wait for the CI pipelines to finish. Renovate should automatically create a PR in `buildbot` with the latest `build-image` releases (this may not happen straight away, but you can speed it up by checking [the box in this PR](https://github.com/netlify/buildbot/issues/912) or manually create a PR to bump [the version](https://github.com/netlify/buildbot/blob/0ada244ab84a1759a70d6b2cfc27c9987b5c77ca/.circleci/config.yml#L141-L150)).
5. Review, test and deploy the PR in `buildbot`.
### Running Test `buildbot` Releases

If you want to test a particular `build-image` change before going through the regular release process, you can do so by creating a PR following the process above :point-up: and pointing to any `build-image` you want. Any branch
creates a valid `build-image` tag in the docker registry. Once the PR in `buildbot` is created, you can test your `build-image` change by referring to `buildbot`'s [test instructions](https://github.com/netlify/buildbot#testing-builds-on-a-live-test-site).

## License

By contributing to Netlify's build-image, you agree that your contributions will be licensed
under its [MIT license](LICENSE).
