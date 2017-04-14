# Netlify Build Image

This repository contains the tols to make the build image Netlify uses to build a site from git (for continuous deployment.)

Use this image to test locally if you're having build issues.

## Testing locally

Run the image in interactive mode, and make sure to mount your repo as a volume, install
the dependencies that are relevant to your project, and then run your build command:

```
cd path/to/my/repo
docker run -t -i -v ${PWD}:/opt/repo netlify/build /bin/bash
build jekyll build
```

Replace `jekyll build` with your build command of choice.

If you'd like to run a similar process as our buildbots you can run the embedded scripts

```
cd path/to/this/repo
./test-build.sh path/to/your/repo 'your build command'
```

This will create a tmp directory that will have the repo we cloned, the cache (with hidden files), and the scripts we ran.
You can run also run with that cache by prepending `T=tmp/tmp.XXXXX` to the build command.

## Contributing

Pull requests welcome, as long as they're not overly specific to a niche use-case.

## More info

How we use this and some best practices are documented here: https://www.netlify.com/blog/2016/10/18/how-our-build-bots-build-sites/
