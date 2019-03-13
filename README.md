# Netlify Build Image

This repository contains the tools to make the build image Netlify uses to build a site from git (for continuous deployment.)

You can also use the image this generates to test locally if you're having build issues.

## Running Locally

To use this tool, you must first clone it:
```
git clone netlify/build-image
```

Next, the Docker Image needs to be built, which takes a long time, instead we recommend get the latest version of the image that we've published, pre-built for your testing pleasure:
```
docker pull netlify/build
```

### Usage
Prerequisites:
1. This repository cloned locally
2. The reposotory you would like to test also cloned locally
3. Be sure to have a clean git status in the test repository (e.g. commit or stash).
4. Ensure the test repository's branch is the inteneded one to be built

Interactive Mode:
1. To run the test image in interactive mode, run the following command: `./test-tools/start-image.sh path/to/my/repo`.  This will open an interactive shell within the container
2. Within that container's shell, use our 'build' script to simulate your build in our environment, using your own build command: `build jekyll build` (Replace `jekyll build` with your build command of choice.)

Note that local testing will not incorporate your Build Environment Variables from our UI or any settings from netlify.toml.  You will need to "apply" the correct settings and build command manually, for instance:

```
export NODE_VERSION=6 NODE_ENV=production ; build npm run build
```

## Testing locally with cache

If you'd like to run a debugging build using our caching mechanisms, with verbose shell output, you can instead use `test-tools/test-build.sh path/to/your/repo 'your build command'`

This will create a tmp directory that will have the repo we cloned, the cache (with hidden files), and the scripts we ran.
You can run also run with that cache by prepending `T=tmp/tmp.XXXXX` to the build command.

## Contributing

Pull requests welcome, as long as they're not overly specific to a niche use-case.

## More info

How we use this and some best practices are documented here: https://www.netlify.com/blog/2016/10/18/how-our-build-bots-build-sites/
