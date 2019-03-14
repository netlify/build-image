## Included Software: Trusty

This is the **Trusty** build image. It runs on Ubuntu version 14.04 (aka Trusty), and includes the languages and software versions listed below.

For instructions on how to run this image locally to test your build, please see the [README](/README.md).

### Languages

The specific patch versions included will depend on when the image was last built (except Ruby). It is highly suggested you depend only on minor versions, so that we can ensure the language has the latest updates (especially if security related).

* Ruby - `RUBY_VERSION`, `.ruby-version`
  * 2.6.2 (default)
  * 2.5.4
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
