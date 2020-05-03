## Included Software: Xenial

This is the **Xenial** build image. It runs on Ubuntu version 16.04 (aka Xenial), and includes the languages and software versions listed below.

For instructions on how to run this image locally to test your build, please see the [README](/README.md).

### Languages

The specific patch versions included will depend on when the image was last built (except Ruby). It is highly suggested you depend only on minor versions, so that we can ensure the language has the latest updates (especially if security related).

* Ruby - `RUBY_VERSION`, `.ruby-version`
  * 2.6.2 (default)
  * Any version that `rvm` can install.
* Node.js - `NODE_VERSION`, `.nvmrc`, `.node-version`
  * 10 (default)
  * Any version that `nvm` can install.
* Python - `runtime.txt` or `Pipfile`
  * 2.7 (default)
  * 3.5
  * 3.7
* PHP - `PHP_VERSION`
  * 5.6 (default)
  * 7.2
  * 7.4
* Go - `GO_VERSION`
  * 1.12 (default)
* Swift - `SWIFT_VERSION`, `.swift-version`
  * 5.2 (default)
  * Any version that `swiftenv` can install newer than `4.x`. Versions `4.x` and below will not work due to incompatible shared libraries.
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
    * 1.13.0 (default)
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
* [WASMER](https://github.com/wasmerio/wasmer)
* [WAPM](https://github.com/wasmerio/wapm-cli)

* [Homebrew](https://brew.sh/)
  - Any linux formula is supported: https://formulae.brew.sh/formula-linux/
  - Formulae from a `Brewfile` are installed automatically via [`brew bundle`](https://github.com/Homebrew/homebrew-bundle#readme)
  - `HOMEBREW_BUNDLE_FILE` is respected
