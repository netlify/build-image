# Netlify Build Image

This repository contains the tools to make the build image that Netlify's continuous deployment buildbot uses to build a site from a connected Git repository.

If you're having problems with your build, you can also use these tools to test locally.

## Available images

Netlify maintains multiple build images for testing new development as well as supporting legacy builds. Each image uses a different version of Ubuntu Linux, with a slightly different list of included language and software versions.

The following image is currently available:

- `focal` - Default build image for all new sites; Running Ubuntu 20.04 and [this software](https://github.com/netlify/build-image/blob/focal/included_software.md)

Each image name above corresponds to a branch in this repository.

## Running locally

Emulating Netlify's buildbot on your local machine requires the following:

- [Docker](https://docs.docker.com/install/)
- A local clone of this build-image repository
- A local clone of the site repository you want to test, checked out to the branch you want to be built, with a clean git status (nothing to commit).

### Step 1: Pull the build image

Open your Docker terminal, and run the following command to pull the default image:

```
docker pull netlify/build:focal
or
docker pull netlify/build:v3.0.2 # replace the version with a git tag of the specific version you want to test
```

### Step 2: Start the script to run interactively

Still in your Docker terminal, change directories into your local clone of this build-image repository.

If you pulled an alternate image in Step 1, check out the corresponding branch in this repository.

Run the following command to start the interactive shell within the container:

```
./test-tools/start-image.sh path/to/site/repo
```

If you receive a `command not found` message, make sure you are in the base of the build-image repository.

If the command works correctly, you should see a new prompt, with the user `buildbot`.

### Step 3: Have the buildbot run your build command

In the buildbot shell, run `build` followed by your site build command. For example, for a site build command of `npm run build`, you would run the following:

```
/opt/build-bin/build npm run build
```

This will run the build as it would run on Netlify, displaying logs in your terminal as it goes. When you are done testing, you can exit the buildbot shell by typing `exit`.

### Build environment variables

Your local buildbot emulator doesn't have access to build environment variables set in the Netlify UI or netlify.toml file. However, you can explicitly set them in the interactive buildbot shell before running your build command.

Here is an example that sets `NODE_VERSION` and `NODE_ENV` before running a build command of `npm run build`:

```
export NODE_VERSION=8 NODE_ENV=production ; build npm run build
```

### Testing it for a mono repository

If you like to run a debugging build for your mono repository you need to pass the **Base directory** like in the Netlify UI.

```
./test-tools/test-build.sh path/to/site/repo base/directory 'your build command'
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

## Development

Visit the [development section in our CONTRIBUTING.md](CONTRIBUTING.md#development)

## Contributing

Pull requests welcome, as long as they're not overly specific to a niche use-case.

Please see our [contributing documentation](CONTRIBUTING.md).

## More info

How we use this and some best practices are documented here: https://www.netlify.com/blog/2016/10/18/how-our-build-bots-build-sites/
