# Netlify Build Image

This repository contains the tools to make the build image that Netlify's continuous deployment buildbot uses to build a site from a connected Git repository.

If you're having problems with your build, you can also use these tools to test locally.

## Available images

Netlify maintains multiple build images for testing new development as well as supporting legacy builds. Each image uses a different version of Ubuntu Linux, with a slightly different list of included language and software versions. 

The following images are currently available:

- `trusty` - Legacy build image for older sites; running Ubuntu 14.04 and [this software](https://github.com/netlify/build-image/blob/trusty/included_software.md)
- `xenial` - Default build image for all new sites; running Ubuntu 16.04 and [this software](https://github.com/netlify/build-image/blob/xenial/included_software.md)

Each image name above corresponds to a branch in this repository.

## Running locally

Emulating Netlify's buildbot on your local machine requires the following:

- [Docker](https://docs.docker.com/install/)
- A local clone of this build-image repository
- A local clone of the site repository you want to test, checked out to the branch you want to be built, with a clean git status (nothing to commit).

To run the `xenial` image, run the following command:

```
./test-tools/start-xenial.sh path/to/site/repo
```

To run the `trusty` image, run the following command:

```
./test-tools/start-trusty.sh path/to/site/repo
```

If you receive a `command not found` message, make sure you are in the base of the build-image repository.

If the command works correctly, you should see a new prompt, with the user `buildbot`.

Finally, in the buildbot shell, run `build` followed by your site build command. For example, for a site build command of `npm run build`, you would run the following:

```
build npm run build
```

This will run the build as it would run on Netlify, displaying logs in your terminal as it goes. When you are done testing, you can exit the buildbot shell by typing `exit`.

## Running a different tag or image

To run a Docker tag other than `xenial` or `trustry`, first pull the image:

```
docker pull netlify/build:v3.0.2 # replace the version with a git tag of the specific version you want to test
```

Next, run `test-tools/start-image.sh` with the environment variable `NETLIFY_IMAGE_TAG` set to the tag you just pulled:

```
NETLIFY_IMAGE_TAG=v3.0.2 ./test-tools/start-image.sh path/to/site/repo
```

To run a different Docker image name that you've pulled or built locally, run `test-tools/start-image.sh` with the environment variable `NETLIFY_IMAGE` set to the image and tag you wish to use:

```
NETLIFY_IMAGE=some-other-image:latest ./test-tools/start-image.sh path/to/site/repo
```

Note that `NETLIFY_IMAGE_TAG` has no effect when `NETLIFY_IMAGE` is defined.

## Building and running locally

If you would like to build the image locally, you can do so with Docker. In the root of this repository, run the following:

```
docker build -t netlify/build .
```

Next, run the image you just built with `test-tools/start-image.sh`:

```
./test-tools/start-image.sh path/to/site/repo
```

If you want to build and run using a specific tag, do the following:

```
docker build -t netlify/build:a-tag .
NETLIFY_IMAGE_TAG=a-tag ./test-tools/start-image.sh path/to/site/repo
```

If you want to use an entirely separate image name, do the following:

```
docker build -t another-image-name .
NETLIFY_IMAGE=another-image-name ./test-tools/start-image.sh path/to/site/repo
```

Note that `NETLIFY_IMAGE_TAG` has no effect if `NETLIFY_IMAGE` is defined.

### Build environment variables

Your local buildbot emulator doesn't have access to build environment variables set in the Netlify UI or netlify.toml file. However, you can explicitly set them in the interactive buildbot shell before running your build command.

Here is an example that sets `NODE_VERSION` and `NODE_ENV` before running a build command of `npm run build`:

```
export NODE_VERSION=8 NODE_ENV=production ; build npm run build
```

### Testing locally with cache

If you'd like to run a debugging build using our caching mechanisms, with verbose shell output, you can replace steps 2 and 3 above with the following command:

```
./test-tools/test-build.sh path/to/site/repo 'your build command'
```

This will create a `tmp` directory that will have the repo that the buildbot cloned, the scripts run by the buildbot, and the cache (with hidden files). The terminal displays the path to the `tmp` directory at the start of each build. You specify this path in an environment variable prepended to the command above, like so:

```
T=tmp/tmp.XXXXX ./test-tools/test-build.sh path/to/site/repo 'your build command'
```

## Contributing

Pull requests welcome, as long as they're not overly specific to a niche use-case.

## More info

How we use this and some best practices are documented here: https://www.netlify.com/blog/2016/10/18/how-our-build-bots-build-sites/
