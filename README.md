# Netlify Build Image

This repository contains the tools to make the build image Netlify uses to build a site from git (for continuous deployment.)

You can also use the image this generates to test locally if you're having build issues.

## Testing locally

The image takes a long time to build.  You can instead:

```
docker pull netlify/build
```

to get the latest version we've published, pre-built for your testing pleasure.  To use it, these steps are recommended:

1. Clone your repo into a local directory.  If you are working from a local copy with changes, commit those changes, and be sure you are on the branch with those changes, otherwise we will ignore them during the build.
2. Using our tool from the base of a checkout of our build-image repository, Run the image in interactive mode, mounting your repository as a volume: `./test-tools/start-image.sh path/to/my/repo`
3. Within the container, use our 'build' script to simulate your build in our environment, using your own build command:  `build jekyll build` (Replace `jekyll build` with your build command of choice.)

If you'd like to run a debugging build using our caching mechanisms, with verbose shell output, you can instead use `test-tools/test-build.sh path/to/your/repo 'your build command'`

This will create a tmp directory that will have the repo we cloned, the cache (with hidden files), and the scripts we ran.
You can run also run with that cache by prepending `T=tmp/tmp.XXXXX` to the build command.

## Contributing

Pull requests welcome, as long as they're not overly specific to a niche use-case.

## More info

How we use this and some best practices are documented here: https://www.netlify.com/blog/2016/10/18/how-our-build-bots-build-sites/
