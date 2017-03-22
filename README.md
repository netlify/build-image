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

## Contributing

Pull requests welcome, as long as they're not overly specific to a niche use-case.

## More info

How we use this and some best practices are documented here: https://www.netlify.com/blog/2016/10/18/how-our-build-bots-build-sites/
