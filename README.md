# Netlify Build Image

This repository contains the tools to make the build image Netlify uses to build a site from git (for continuous deployment.)

You can also use the image this generates to test locally if you're having build issues.

## Included Software

### Languages

The specific patch versions included will depend on when the image was last built (except Ruby). It is highly suggested you depend only on minor versions, so that we can ensure the language has the latest updates (especially if security related).

* Ruby - `RUBY_VERSION`, `.ruby-version`
  * 2.2.9
  * 2.3.6 (default)
  * 2.4.3
  * Any version that `rvm` can install.
* Node.js - `NODE_VERSION`, `.nvmrc`, `.node-version`
  * 4
  * 6
  * 8 (default)
  * Any version that `nvm` can install.
* Python - `runtime.txt` or `Pipfile`
  * 2.7 (default)
  * 3.4
  * 3.5
  * 3.6
* PHP - `PHP_VERSION`
  * 5.6 (default)
  * 7.2
* Java
  * 8 (default)
* Emacs
  * 25 (default)

### Tools

* Node.js
  * Yarn - `YARN_VERSION`
    * 1.3.2 (default)
    * Any version available via their installer.
  * NPM - `NPM_VERSION`
    * Version corresponding with Node.js version. (default)
    * Any version available via NPM.
  * bower
* Python
  * pip
    * Version corresponding with Python version. (default)
  * Pipenv
    * Latest version.
* PHP
  * Composer
* Emacs
  * Cask
* Clojure
  * Leiningen
    * stable
  * Boot
    * 2.5.2
* Hugo - `HUGO_VERSION`
  * 0.17 (default)
  * 0.18
  * 0.19
  * 0.20
  * Any version installable via `binrc`.
* Gutenburg - `GUTENBERG_VERSION`
  * Any version installable via `binrc`.

## Testing locally

The image takes a long time to build. You can instead:

```
docker pull netlify/build
```

to get the latest version we've published, pre-built for your testing pleasure. To use it, these steps are recommended:

1. Clone your repo into a local directory. If you are working from a local copy with changes, commit those changes (no need to push to a git provider, just commit), and be sure you are on the branch with those changes, otherwise we will ignore them during the build.
2. Using our tool from the base of a checkout of our build-image repository, Run the image in interactive mode, mounting your repository as a volume: `./test-tools/start-image.sh path/to/my/repo`
3. Within the container, use our 'build' script to simulate your build in our environment, using your own build command: `build jekyll build` (Replace `jekyll build` with your build command of choice.)

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
