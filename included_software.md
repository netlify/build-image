## Included Software: Focal

This is the **Focal** build image. It runs on Ubuntu version 20.04 (aka Focal Fossa), and includes the languages and software versions listed below.

For instructions on how to run this image locally to test your build, please see the [README](/README.md).

### Languages

The specific patch versions included will depend on when the image was last built (except Ruby). It is highly suggested you depend only on minor versions, so that we can ensure the language has the latest updates (especially if security related).

* Ruby - `RUBY_VERSION`, `.ruby-version`
  * 2.7 (default)
  * 2.6
  * Any version that `rvm` can install.
* Node.js - `NODE_VERSION`, `.nvmrc`, `.node-version`
  * 16.4 (default)
  * Any version that `nvm` can install.
* Python - `PYTHON_VERSION`, `runtime.txt`, `Pipfile`
  * 3.9 (default)
  * 3.8
  * 2.7
* PHP - `PHP_VERSION`
  * 7.4 (default)
* Go - `GO_VERSION`
  * 1.16 (default)
* Java
  * 8 (default)
* Emacs
  * 26.3 (default)
* Erlang
  * 22.2 (default)
* Elixir
  * 1.9.1 (default)
* Swift - `SWIFT_VERSION`, `.swift-version`
  * Not installed by default.
  * Supports any version that `swiftenv` can install later than `4.x`. Versions `4.x` and earlier will not work due to incompatible shared libraries.
  * 5.4 is installed if `Package.swift` is present and no version is specified with `SWIFT_VERSION` or `.swift-version`.
* Rust
  * Not installed by default.
  * Supports any version that `rustup` can install.

### Tools

* Node.js
  * Yarn - `YARN_VERSION`
    * 1.22.10 (default)
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
  * 0.82 extended (default)
  * Any version installable via `binrc`.
* Gutenburg - `GUTENBERG_VERSION`
  * Any version installable via `binrc`.
* Zola - `ZOLA_VERSION`
  * Any version installable via `binrc`.
* [jq](https://stedolan.github.io/jq/) - 1.6
* [ImageMagick](https://www.imagemagick.org) - 6.9.10 (default)
* [GNU Make](https://www.gnu.org/software/make/) - 3.81
* OptiPNG - 0.6.4
* [Doxygen](http://www.doxygen.org) - 1.8.17

* [Homebrew](https://brew.sh/) - **EARLY ALPHA**
  - this is not production ready
  - it might be removed or changed significantly
  - Any linux formula is supported: https://formulae.brew.sh/formula-linux/
  - Formulae from a `Brewfile.netlify` are installed automatically via [`brew bundle`](https://github.com/Homebrew/homebrew-bundle#readme)
  - `HOMEBREW_BUNDLE_FILE` is respected
