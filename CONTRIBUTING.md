# CONTRIBUTING

Contributions are always welcome, no matter how large or small. Before contributing,
please read the [code of conduct](CODE_OF_CONDUCT.md).

## Releasing

1. `npm version major`, `npm version minor`, `npm version patch` or `npm version prerelease`: generate changelog, bump version, version commit + tag.
2. `npm run release`: push version commit + tag, push latest CHANGELOG entry to GitHub release page.
3. Wait for Jenkins build to finish
4. Create a PR in the [buildbot](https://github.com/netlify/buildbot) to bump [the version](https://github.com/netlify/buildbot/blob/a247edab7ead955cc27bb70ecc9f081e68f1aea6/script/docker-build.sh#L17) of the `build-image`.

## License

By contributing to Netlify's build-image, you agree that your contributions will be licensed
under its [MIT license](LICENSE).
