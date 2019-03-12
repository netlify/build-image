# Netlify Build Image

This repository contains the tools to make the build image Netlify uses to build a site from git (for continuous deployment.)

You can also use the image this generates to test locally if you're having build issues.

## Included Software

### Languages

The specific patch versions included will depend on when the image was last built (except Ruby). It is highly suggested you depend only on minor versions, so that we can ensure the language has the latest updates (especially if security related).

* Ruby - `RUBY_VERSION`, `.ruby-version`
  * 2.6.1 (default)
  * 2.5.3
  * 2.4.5
  * Any version that `rvm` can install.
* Node.js - `NODE_VERSION`, `.nvmrc`, `.node-version`
  * 10 (default)
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
* Erlang
  * 21 (default)
* Elixir
  * 1.7 (default)

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
  * 0.54 extended (default)
  * Any version installable via `binrc`.
* Gutenburg - `GUTENBERG_VERSION`
  * Any version installable via `binrc`.
* [jq](https://stedolan.github.io/jq/) - 1.5
* [ImageMagick](https://www.imagemagick.org) - 6.7.7
* [GNU Make](https://www.gnu.org/software/make/) - 3.81
* OptiPNG - 0.6.4
* [Doxygen](http://www.doxygen.org) - 1.8.6

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
