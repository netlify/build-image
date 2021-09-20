# CONTRIBUTING

Contributions are always welcome, no matter how large or small. Before contributing,
please read the [code of conduct](CODE_OF_CONDUCT.md).

## Releasing

1. Merge the relevant package release PR created by `release-please`
2. Wait for the Jenkins build to finish
3. Create a PR in the [buildbot](https://github.com/netlify/buildbot) to bump [the version](https://github.com/netlify/buildbot/blob/ddbb47739f5b85c954aad9dc3823ab0676432957/Jenkinsfile#L35) of the `build-image`.

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

## License

By contributing to Netlify's build-image, you agree that your contributions will be licensed
under its [MIT license](LICENSE).
