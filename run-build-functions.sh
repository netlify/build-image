#!/bin/bash
# helper to check if we need to install deps
# install_deps configuration_file version shasum_file

if [ $NETLIFY_VERBOSE ]
then
  set -x
fi

: ${NETLIFY_BUILD_BASE="/opt/buildhome"}
NETLIFY_CACHE_DIR="$NETLIFY_BUILD_BASE/cache"
NETLIFY_REPO_DIR="$NETLIFY_BUILD_BASE/repo"

export GIMME_TYPE=binary
export GIMME_NO_ENV_ALIAS=true
export GIMME_CGO_ENABLED=true

export NVM_DIR="$HOME/.nvm"
export RVM_DIR="$HOME/.rvm"

# Swift configuration
export SWIFTENV_ROOT="${SWIFTENV_ROOT:-${HOME}/.swiftenv}"
DEFAULT_SWIFT_VERSION="5.4"

# PHP version
DEFAULT_PHP_VERSION="7.4"

# Pipenv configuration
export PIPENV_RUNTIME=3.9
export PIPENV_VENV_IN_PROJECT=1
export PIPENV_DEFAULT_PYTHON_VERSION=3.9

# CI signal
export NETLIFY=true

YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# language versions
mkdir -p $NETLIFY_CACHE_DIR/node_version
mkdir -p $NETLIFY_CACHE_DIR/ruby_version
mkdir -p $NETLIFY_CACHE_DIR/swift_version

# pwd caches
NETLIFY_JS_WORKSPACES_CACHE_DIR="$NETLIFY_CACHE_DIR/js-workspaces"

mkdir -p $NETLIFY_JS_WORKSPACES_CACHE_DIR
mkdir -p $NETLIFY_CACHE_DIR/node_modules
mkdir -p $NETLIFY_CACHE_DIR/.bundle
mkdir -p $NETLIFY_CACHE_DIR/bower_components
mkdir -p $NETLIFY_CACHE_DIR/.venv
mkdir -p $NETLIFY_CACHE_DIR/.build
mkdir -p $NETLIFY_CACHE_DIR/.netlify/plugins

# HOME caches
mkdir -p $NETLIFY_CACHE_DIR/.yarn_cache
mkdir -p $NETLIFY_CACHE_DIR/.cache/pip
mkdir -p $NETLIFY_CACHE_DIR/.cask
mkdir -p $NETLIFY_CACHE_DIR/.emacs.d
mkdir -p $NETLIFY_CACHE_DIR/.m2
mkdir -p $NETLIFY_CACHE_DIR/.boot
mkdir -p $NETLIFY_CACHE_DIR/.composer
mkdir -p $NETLIFY_CACHE_DIR/.gimme_cache/gopath
mkdir -p $NETLIFY_CACHE_DIR/.gimme_cache/gocache
mkdir -p $NETLIFY_CACHE_DIR/.homebrew-cache
mkdir -p $NETLIFY_CACHE_DIR/.cargo

: ${YARN_FLAGS=""}
: ${NPM_FLAGS=""}
: ${BUNDLER_FLAGS=""}

install_deps() {
  [ -f $1 ] || return 0
  [ -f $3 ] || return 0

  SHA1="$(shasum $1)-$2"
  SHA2="$(cat $3)"
  if [ "$SHA1" == "$SHA2" ]
  then
    return 1
  else
    return 0
  fi
}

run_yarn() {
  yarn_version=$1
  if [ -d $NETLIFY_CACHE_DIR/yarn ]
  then
    export PATH=$NETLIFY_CACHE_DIR/yarn/bin:$PATH
  fi
  restore_home_cache ".yarn_cache" "yarn cache"

  if [ $(which yarn) ] && [ "$(yarn --version)" != "$yarn_version" ]
  then
    echo "Found yarn version ($(yarn --version)) that doesn't match expected ($yarn_version)"
    rm -rf $NETLIFY_CACHE_DIR/yarn $HOME/.yarn
    npm uninstall yarn -g
  fi

  if ! [ $(which yarn) ]
  then
    echo "Installing yarn at version $yarn_version"
    rm -rf $HOME/.yarn
    bash /usr/local/bin/yarn-installer.sh --version $yarn_version
    mv $HOME/.yarn $NETLIFY_CACHE_DIR/yarn
    export PATH=$NETLIFY_CACHE_DIR/yarn/bin:$PATH
  fi


  local workspace_output
  local workspace_exit_code
  # YARN_IGNORE_PATH will ignore the presence of a local yarn executable (i.e. yarn 2) and default
  # to using the global one (which, for now, is always yarn 1.x). See https://yarnpkg.com/configuration/yarnrc#ignorePath
  workspace_output="$(YARN_IGNORE_PATH=1 yarn workspaces --json info 2>/dev/null)"
  workspace_exit_code=$?
  if [ $workspace_exit_code -eq 0 ]
  then
    echo "Yarn workspaces detected"
    local package_locations
    # Extract all the packages and respective locations. .data will be a JSON object like
    # {
    #   "my-package-1": {
    #     "location": "packages/blog-1",
    #     "workspaceDependencies": [],
    #     "mismatchedWorkspaceDependencies": []
    #   },
    #   (...)
    # }
    # We need to cache all the node_module dirs, or we'll always be installing them on each run
    mapfile -t package_locations <<< "$(echo "$workspace_output" | jq -r '.data | fromjson | to_entries | .[].value.location')"
    restore_js_workspaces_cache "${package_locations[@]}"
  else
    echo "No yarn workspaces detected"
    restore_cwd_cache node_modules "node modules"
  fi

  echo "Installing NPM modules using Yarn version $(yarn --version)"
  run_npm_set_temp

  # Remove the cache-folder flag if the user set any.
  # We want to control where to put the cache
  # to be able to store it internally after the build.
  local yarn_local="${YARN_FLAGS/--cache-folder * /}"
  # The previous pattern doesn't match the end of the string.
  # This removes the flag from the end of the string.
  yarn_local="${yarn_local%--cache-folder *}"

  if yarn install --cache-folder $NETLIFY_BUILD_BASE/.yarn_cache ${yarn_local:+"$yarn_local"}
  then
    echo "NPM modules installed using Yarn"
  else
    echo "Error during Yarn install"
    exit 1
  fi
  export PATH=$(yarn bin):$PATH
}

run_npm_set_temp() {
  # Make sure we're not limited by space in the /tmp mount
  mkdir $HOME/tmp
  npm set tmp $HOME/tmp
}

run_npm() {
  restore_cwd_cache node_modules "node modules"

  if [ -n "$NPM_VERSION" ]
  then
    if [ "$(npm --version)" != "$NPM_VERSION" ]
    then
      echo "Found npm version ($(npm --version)) that doesn't match expected ($NPM_VERSION)"
      echo "Installing npm at version $NPM_VERSION"
      if npm install -g npm@$NPM_VERSION
      then
        echo "NPM installed successfully"
      else
        echo "Error installing NPM"
        exit 1
      fi
    fi
  fi

  if install_deps package.json $NODE_VERSION $NETLIFY_CACHE_DIR/package-sha
  then
    echo "Installing NPM modules using NPM version $(npm --version)"
    run_npm_set_temp
    if npm install ${NPM_FLAGS:+"$NPM_FLAGS"}
    then
      echo "NPM modules installed"
    else
      echo "Error during NPM install"
      exit 1
    fi

    echo "$(shasum package.json)-$NODE_VERSION" > $NETLIFY_CACHE_DIR/package-sha
  fi
  export PATH=$(npm bin):$PATH
}

check_python_version() {
  if source $HOME/python${PYTHON_VERSION}/bin/activate
  then
    echo "Python version set to ${PYTHON_VERSION}"
  else
    echo "Error setting python version from $1"
    echo "Please see https://github.com/netlify/build-image/#included-software for current versions"
    exit 1
  fi
}

install_dependencies() {
  local defaultNodeVersion=$1
  local defaultRubyVersion=$2
  local defaultYarnVersion=$3
  local installGoVersion=$4
  local defaultPythonVersion=$5

  # Python Version
  if [ -f runtime.txt ]
  then
    PYTHON_VERSION=$(cat runtime.txt)
    check_python_version "runtime.txt"
  elif [ -f Pipfile ]
  then
    echo "Found Pipfile restoring Pipenv virtualenv"
    restore_cwd_cache ".venv" "python virtualenv"
  else
    PYTHON_VERSION=$defaultPythonVersion
    check_python_version "the PYTHON_VERSION environment variable"
  fi

  # Node version
  source $NVM_DIR/nvm.sh
  : ${NODE_VERSION="$defaultNodeVersion"}

  # restore only non-existing cached versions
  if [[ $(ls $NETLIFY_CACHE_DIR/node_version/) ]]
  then
    echo "Started restoring cached node version"
    rm -rf "$NVM_DIR/versions/node"
    mkdir "$NVM_DIR/versions/node"
    cp -p -r $NETLIFY_CACHE_DIR/node_version/* $NVM_DIR/versions/node/
    echo "Finished restoring cached node version"
  fi

  if [ -f .nvmrc ]
  then
    NODE_VERSION=$(cat .nvmrc)
    echo "Attempting node version '$NODE_VERSION' from .nvmrc"
  elif [ -f .node-version ]
  then
    NODE_VERSION=$(cat .node-version)
    echo "Attempting node version '$NODE_VERSION' from .node-version"
  fi

  if nvm install --no-progress $NODE_VERSION
  then
    NODE_VERSION=$(nvm current)
    # no echo needed because nvm does that for us
    export NODE_VERSION=$NODE_VERSION

    if [ "$NODE_VERSION" == "none" ]
    then
      nvm debug
      env
    fi
  else
    echo "Failed to install node version '$NODE_VERSION'"
    exit 1
  fi

  if [ -n "$NPM_TOKEN" ]
  then
    if [ ! -f .npmrc ]
    then
      echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > .npmrc
    fi
  fi

  # Automatically installed Build plugins
  if [ ! -d "$PWD/.netlify" ]
  then
    mkdir "$PWD/.netlify"
  fi
  restore_cwd_cache ".netlify/plugins" "build plugins"

  # Ruby version
  local tmprv="${RUBY_VERSION:=$defaultRubyVersion}"
  source $HOME/.rvm/scripts/rvm
  # rvm will overwrite RUBY_VERSION, so we must control it
  export RUBY_VERSION=$tmprv

  local druby=$RUBY_VERSION
  if [ -f .ruby-version ]
  then
    druby=$(cat .ruby-version)
    echo "Attempting ruby version ${druby}, read from .ruby-version file"
  else
    echo "Attempting ruby version ${druby}, read from environment"
  fi

  rvm use ${druby} > /dev/null 2>&1
  export CUSTOM_RUBY=$?
  local rvs=($(rvm list strings))

  local fulldruby="ruby-${druby}"
  if [ -d $NETLIFY_CACHE_DIR/ruby_version/${fulldruby} ]
  then
    echo "Started restoring cached ruby version"
    rm -rf $RVM_DIR/rubies/${fulldruby}
    cp -p -r $NETLIFY_CACHE_DIR/ruby_version/${fulldruby} $RVM_DIR/rubies/
    echo "Finished restoring cached ruby version"
  fi

  rvm --create use ${druby} > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    local crv=$(rvm current)
    export RUBY_VERSION=${crv#ruby-}
    echo "Using ruby version ${RUBY_VERSION}"
  else
    if rvm_install_on_use_flag=1 rvm --quiet-curl --create use ${druby}
    then
      local crv=$(rvm current)
      export RUBY_VERSION=${crv#ruby-}
      echo "Using ruby version ${RUBY_VERSION}"
    else
      echo "Failed to install ruby version '${druby}'"
      exit 1
    fi
  fi

  # get bundler version
  local bundler_version
  if [ -f Gemfile.lock ]
  then
     bundler_version="$(cat Gemfile.lock | grep -C1 '^BUNDLED WITH$' | tail -n1 | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//' | tr -d \\n)"
  fi

  if ! [ -z "$bundler_version" ]
  then
      echo "Using bundler version $bundler_version from Gemfile.lock"
  fi

  if ! gem list -i "^bundler$" -v "$bundler_version" > /dev/null 2>&1
  then
      local bundler_gem_name
      if [ -z "$bundler_version" ]
      then
          bundler_gem_name=bundler
      else
          bundler_gem_name="bundler:$bundler_version"
      fi
      if ! gem install "$bundler_gem_name" --no-document
      then
          echo "Error installing bundler"
          exit 1
      fi
  fi

  # Java version
  export JAVA_VERSION=default_sdk

  # PHP version
  : ${PHP_VERSION="$DEFAULT_PHP_VERSION"}
  if [ -f /usr/bin/php$PHP_VERSION ]
  then
    if ln -sf /usr/bin/php$PHP_VERSION $HOME/.php/php
    then
      echo "Using PHP version $PHP_VERSION"
    else
      echo "Failed to switch to PHP version $PHP_VERSION"
      exit 1
    fi
  else
    echo "PHP version $PHP_VERSION does not exist"
    exit 1
  fi

  # Rubygems
  if [ -f Gemfile ]
  then
    restore_cwd_cache ".bundle" "ruby gems"
    if install_deps Gemfile.lock $RUBY_VERSION $NETLIFY_CACHE_DIR/gemfile-sha || [ ! -d .bundle ]
    then
      local bundle_command
      if [ -z "$bundler_version" ]
      then
          bundle_command="bundle"
      else
          bundle_command="bundle _${bundler_version}_"
      fi
      echo "Installing gem bundle"
      if $bundle_command install --path $NETLIFY_CACHE_DIR/bundle --binstubs=$NETLIFY_CACHE_DIR/binstubs ${BUNDLER_FLAGS:+"$BUNDLER_FLAGS"}
      then
      export PATH=$NETLIFY_CACHE_DIR/binstubs:$PATH
        echo "Gem bundle installed"
      else
        echo "Error during gem install"
        exit 1
      fi
      echo "$(shasum Gemfile.lock)-$RUBY_VERSION" > $NETLIFY_CACHE_DIR/gemfile-sha
    else
      export PATH=$NETLIFY_CACHE_DIR/binstubs:$PATH
    fi
  fi

  # PIP dependencies
  if [ -f requirements.txt ]
  then
    echo "Installing pip dependencies"
    restore_home_cache ".cache/pip" "pip cache"
    if pip install -r requirements.txt
    then
      echo "Pip dependencies installed"
    else
      echo "Error installing pip dependencies"
      exit 1
    fi
  elif [ -f Pipfile ]
  then
    echo "Installing dependencies from Pipfile"
    if $HOME/python$PIPENV_RUNTIME/bin/pipenv install
    then
      echo "Pipenv dependencies installed"
      if source $($HOME/python$PIPENV_RUNTIME/bin/pipenv --venv)/bin/activate
      then
        echo "Python version set to $(python -V)"
      else
        echo "Error activating Pipenv environment"
        exit 1
      fi
    else
      echo "Error installing Pipenv dependencies"
      echo "Please see https://github.com/netlify/build-image/#included-software for current versions"
      exit 1
    fi
  fi

  # Swift Version
  if [ -f .swift-version ]
  then
    SWIFT_VERSION=$(cat .swift-version)
    echo "Attempting Swift version '$SWIFT_VERSION' from .swift-version"
  fi

  # If Package.swift is present and no Swift version is set, use a default
  if [ -f Package.swift ]
  then
    : ${SWIFT_VERSION="$DEFAULT_SWIFT_VERSION"}
  fi

  if [ -n "$SWIFT_VERSION" ]
  then
    if [ -d $NETLIFY_CACHE_DIR/swift_version/$SWIFT_VERSION ]
    then
      echo "Started restoring cached Swift version"
      mkdir -p "$SWIFTENV_ROOT/versions"
      cp -p -r "$NETLIFY_CACHE_DIR/swift_version/$SWIFT_VERSION/" "$SWIFTENV_ROOT/versions/"
      swiftenv rehash
      echo "Finished restoring cached Swift version"
    fi

    # swiftenv expects the following environment variables to refer to
    # swiftenv internals
    if PLATFORM='' URL='' VERSION='' swiftenv install -s $SWIFT_VERSION
    then
      echo "Using Swift version $SWIFT_VERSION"
    else
      echo "Failed to install Swift version '$SWIFT_VERSION'"
      exit 1
    fi
  fi

  # SPM dependencies
  if [ -f Package.swift ]
  then
    echo "Building Swift Package"
    restore_cwd_cache ".build" "swift build"
    if swift build
    then
      echo "Swift package Built"
    else
      echo "Error building Swift package"
      exit 1
    fi
  fi

  # Homebrew from Brewfile
  if [ -f Brewfile.netlify ] || [ ! -z "$HOMEBREW_BUNDLE_FILE" ]
  then
    : ${HOMEBREW_BUNDLE_FILE:="Brewfile.netlify"}
    export HOMEBREW_BUNDLE_FILE
    echo "Installing Homebrew dependencies from ${HOMEBREW_BUNDLE_FILE}"
    brew bundle
  fi

  # NPM Dependencies
  : ${YARN_VERSION="$defaultYarnVersion"}
  : ${CYPRESS_CACHE_FOLDER="./node_modules/.cache/CypressBinary"}
  export CYPRESS_CACHE_FOLDER

  if [ -f package.json ]
  then
    if [ "$NETLIFY_USE_YARN" = "true" ] || ([ "$NETLIFY_USE_YARN" != "false" ] && [ -f yarn.lock ])
    then
      run_yarn $YARN_VERSION
    else
      run_npm
    fi
  fi

  # Bower Dependencies
  if [ -f bower.json ]
  then
    if ! [ $(which bower) ]
    then
      if [ "$NETLIFY_USE_YARN" = "true" ] || ([ "$NETLIFY_USE_YARN" != "false" ] && [ -f yarn.lock ])
      then
        echo "Installing bower with Yarn"
        yarn add bower
      else
        echo "Installing bower with NPM"
        npm install bower
      fi
      export PATH=$(npm bin):$PATH
    fi
    restore_cwd_cache bower_components "bower components"
    echo "Installing bower components"
    if bower install --config.interactive=false
    then
      echo "Bower components installed"
    else
      echo "Error installing bower components"
      exit 1
    fi
  fi

  # Leiningen
  if [ -f project.clj ]
  then
    restore_home_cache ".m2" "maven dependencies"
    if install_deps project.clj $JAVA_VERSION $NETLIFY_CACHE_DIR/project-clj-sha
    then
      echo "Installing Leiningen dependencies"
      if lein deps
      then
        echo "Leiningen dependencies installed"
      else
        echo "Error during Leiningen install"
        exit 1
      fi
      echo "$(shasum project.clj)-$JAVA_VERSION" > $NETLIFY_CACHE_DIR/project-clj-sha
    else
      echo "Leiningen dependencies found in cache"
    fi
  fi

  # Boot
  if [ -f build.boot ]
  then
    restore_home_cache ".m2" "maven dependencies"
    restore_home_cache ".boot" "boot dependencies"
    if install_deps build.boot $JAVA_VERSION $NETLIFY_CACHE_DIR/project-boot-sha
    then
      echo "Installing Boot dependencies"
      if boot pom jar install
      then
        echo "Boot dependencies installed"
      else
        echo "Error during Boot install"
        exit 1
      fi
      echo "$(shasum build.boot)-$JAVA_VERSION" > $NETLIFY_CACHE_DIR/project-boot-sha
    else
      echo "Boot dependencies found in cache"
    fi
  fi

  # Hugo
  if [ -n "$HUGO_VERSION" ]
  then
    echo "Installing Hugo $HUGO_VERSION"
    hugoOut=$(binrc install -c $NETLIFY_CACHE_DIR/.binrc-$(binrc version) hugo)
    if [ $? -eq 0 ]
    then
      export PATH=$(dirname $hugoOut):$PATH
      hugo version
    else
      echo "Error during Hugo $HUGO_VERSION install: $hugoOut"
      exit 1
    fi
  fi

  # Gutenberg
  if [ -n "$GUTENBERG_VERSION" ]
  then
    echo "Installing Gutenberg $GUTENBERG_VERSION"
    gutenbergOut=$(binrc install -c $NETLIFY_CACHE_DIR/.binrc-$(binrc version) gutenberg)
    if [ $? -eq 0 ]
    then
      export PATH=$(dirname $gutenbergOut):$PATH
    else
      echo "Error during Gutenberg $GUTENBERG_VERSION install: $gutenbergOut"
      exit 1
    fi
  fi

  # Zola
  if [ -n "$ZOLA_VERSION" ]
  then
    echo "Installing Zola $ZOLA_VERSION"
    zolaOut=$(binrc install -c $NETLIFY_CACHE_DIR/.binrc-$(binrc version) zola)
    if [ $? -eq 0 ]
    then
      export PATH=$(dirname $zolaOut):$PATH
    else
      echo "Error during Zola $ZOLA_VERSION install: $zolaOut"
      exit 1
    fi
  fi

  # Cask
  if [ -f Cask ]
  then
    restore_home_cache ".cask" "emacs cask dependencies"
    restore_home_cache ".emacs.d" "emacs cache"
    if cask install
    then
      echo "Emacs packages installed"
      fi
  fi

  # PHP Composer dependencies
  if [ -f composer.json ]
  then
    restore_home_cache ".composer" "composer dependencies"
    composer install
  fi

  # Go version
  restore_home_cache ".gimme_cache" "go cache"
  if [ -f .go-version ]
  then
    local goVersion=$(cat .go-version)
    if [ "$installGoVersion" != "$goVersion" ]
    then
      installGoVersion="$goVersion"
    fi
  fi

  if [ "$GIMME_GO_VERSION" != "$installGoVersion" ]
  then
    echo "Installing Go version $installGoVersion"
    GIMME_ENV_PREFIX=$HOME/.gimme_cache/env GIMME_VERSION_PREFIX=$HOME/.gimme_cache/versions gimme $installGoVersion
    if [ $? -eq 0 ]
    then
      source $HOME/.gimme_cache/env/go$installGoVersion.linux.amd64.env
    else
      echo "Failed to install Go version '$installGoVersion'"
      exit 1
    fi
  else
    gimme | bash
    if [ $? -eq 0 ]
    then
      source $HOME/.gimme/env/go$GIMME_GO_VERSION.linux.amd64.env
    else
      echo "Failed to install Go version '$GIMME_GO_VERSION'"
      exit 1
    fi
  fi

  # Rust
  if [ -f Cargo.toml ] || [ -f Cargo.lock ]
  then
    restore_home_cache ".rustup" "rust rustup cache"
    restore_home_cache ".cargo/registry" "rust cargo registry cache"
    restore_home_cache ".cargo/bin" "rust cargo bin cache"
    restore_cwd_cache "target" "rust compile output"
    source $HOME/.cargo/env
  fi
}

#
# Take things installed during the build and cache them
#
cache_artifacts() {
  echo "Caching artifacts"

  cache_cwd_directory ".bundle" "ruby gems"
  cache_cwd_directory "bower_components" "bower components"

  cache_node_modules

  cache_cwd_directory ".venv" "python virtualenv"
  cache_cwd_directory ".build" "swift build"
  cache_cwd_directory ".netlify/plugins" "build plugins"

  if [ -f Cargo.toml ] || [ -f Cargo.lock ]
  then
    cache_cwd_directory_fast_copy "target" "rust compile output"
  fi

  cache_home_directory ".yarn_cache" "yarn cache"
  cache_home_directory ".cache/pip" "pip cache"
  cache_home_directory ".cask" "emacs cask dependencies"
  cache_home_directory ".emacs.d" "emacs cache"
  cache_home_directory ".m2" "maven dependencies"
  cache_home_directory ".boot" "boot dependencies"
  cache_home_directory ".composer" "composer dependencies"
  cache_home_directory ".homebrew-cache", "homebrew cache"
  cache_home_directory ".rustup" "rust rustup cache"

  if [ -f Cargo.toml ] || [ -f Cargo.lock ]
  then
    cache_home_directory ".cargo/registry" "rust cargo registry cache"
    cache_home_directory ".cargo/bin" "rust cargo bin cache"
  fi

  chmod -R +rw $HOME/.gimme_cache
  cache_home_directory ".gimme_cache" "go dependencies"

  # cache the version of node installed
  if ! [ -d $NETLIFY_CACHE_DIR/node_version/$NODE_VERSION ]
  then
    rm -rf $NETLIFY_CACHE_DIR/node_version
    mkdir $NETLIFY_CACHE_DIR/node_version
    mv $NVM_DIR/versions/node/* $NETLIFY_CACHE_DIR/node_version/
  fi

  # cache the version of ruby installed
  if [[ "$CUSTOM_RUBY" -ne "0" ]]
  then
    if ! [ -d $NETLIFY_CACHE_DIR/ruby_version/ruby-$RUBY_VERSION ]
    then
      rm -rf $NETLIFY_CACHE_DIR/ruby_version
      mkdir $NETLIFY_CACHE_DIR/ruby_version
      mv $RVM_DIR/rubies/ruby-$RUBY_VERSION $NETLIFY_CACHE_DIR/ruby_version/
      echo "Cached ruby version $RUBY_VERSION"
    fi
  else
    rm -rf $NETLIFY_CACHE_DIR/ruby_version
  fi

  # cache the version of Swift installed
  if [ -n "$SWIFT_VERSION" ] && [ -d "$SWIFTENV_ROOT/versions/$SWIFT_VERSION" ]
  then
    if ! [ -d $NETLIFY_CACHE_DIR/swift_version/$SWIFT_VERSION ]
    then
      rm -rf $NETLIFY_CACHE_DIR/swift_version
      mkdir $NETLIFY_CACHE_DIR/swift_version
      mv "$SWIFTENV_ROOT/versions/$SWIFT_VERSION" $NETLIFY_CACHE_DIR/swift_version/
      echo "Cached Swift version $SWIFT_VERSION"
    fi
  else
    rm -rf $NETLIFY_CACHE_DIR/swift_version
  fi
}

move_cache() {
  local src=$1
  local dst=$2
  if [ -d "$src" ]
  then
    echo "Started $3"
    rm -rf "$dst"
    mv "$src" "$dst"
    echo "Finished $3"
  fi
}

fast_copy_cache() {
  local src=$1
  local dst=$2
  if [ -d $src ]
  then
    echo "Started $3"
    cp --reflink=always $src $dst
    echo "Finished $3"
  fi
}

restore_home_cache() {
  move_cache "$NETLIFY_CACHE_DIR/$1" "$HOME/$1" "restoring cached $2"
}

cache_home_directory() {
  move_cache "$HOME/$1" "$NETLIFY_CACHE_DIR/$1" "saving $2"
}

restore_cwd_cache() {
  move_cache "$NETLIFY_CACHE_DIR/$1" "$PWD/$1" "restoring cached $2"
}

#
# Restores node_modules dirs cached for js workspaces
# See https://github.com/netlify/pod-workflow/issues/139/ for more context
#
# Expects:
# $@ each argument should be a package location relative to the repo's root
restore_js_workspaces_cache() {
  # Keep a record of the workspaces in the project in order to cache them later
  NETLIFY_JS_WORKSPACE_LOCATIONS=("$@")

  # Retrieve each workspace node_modules
  for location in "${NETLIFY_JS_WORKSPACE_LOCATIONS[@]}"; do
    move_cache "$NETLIFY_JS_WORKSPACES_CACHE_DIR/$location/node_modules" \
      "$NETLIFY_REPO_DIR/$location/node_modules" \
      "restoring workspace $location node modules"
  done
  # Retrieve hoisted node_modules
  move_cache "$NETLIFY_JS_WORKSPACES_CACHE_DIR/node_modules" "$NETLIFY_REPO_DIR/node_modules" "restoring workspace root node modules"
}

#
# Caches node_modules dirs for a js project. Either detects the presence of js workspaces
# via the `NETLIFY_JS_WORKSPACE_LOCATIONS` variable, or looks at the node_modules in the cwd.
#
cache_node_modules() {
  # Check the number of workspace locations detected
  if [ "${#NETLIFY_JS_WORKSPACE_LOCATIONS[@]}" -eq 0 ]
  then
    cache_cwd_directory "node_modules" "node modules"
  else
    cache_js_workspaces
  fi
}

#
# Caches node_modules dirs from js workspaces. It acts based on the presence of a
# `NETLIFY_JS_WORKSPACE_LOCATIONS` variable previously set in `restore_js_workspaces_cache()`
#
cache_js_workspaces() {
  for location in "${NETLIFY_JS_WORKSPACE_LOCATIONS[@]}"; do
    mkdir -p "$NETLIFY_JS_WORKSPACES_CACHE_DIR/$location"
    move_cache "$NETLIFY_REPO_DIR/$location/node_modules" \
      "$NETLIFY_JS_WORKSPACES_CACHE_DIR/$location/node_modules" \
      "saving workspace $location node modules"
  done
  # Retrieve hoisted node_modules
  move_cache "$NETLIFY_REPO_DIR/node_modules" "$NETLIFY_JS_WORKSPACES_CACHE_DIR/node_modules" "saving workspace root node modules"
}

cache_cwd_directory() {
  move_cache "$PWD/$1" "$NETLIFY_CACHE_DIR/$1" "saving $2"
}

cache_cwd_directory_fast_copy() {
  fast_copy_cache "$PWD/$1" "$NETLIFY_CACHE_DIR/$1" "saving $2"
}

install_missing_commands() {
  if [[ $BUILD_COMMAND_PARSER == *"grunt"* ]]
  then
    if ! [ $(which grunt) ]
    then
      npm install grunt-cli
      export PATH=$(npm bin):$PATH
    fi
  fi
}

set_go_import_path() {
  # Setup project GOPATH
  if [ -n "$GO_IMPORT_PATH" ]
  then
    local importPath="$GOPATH/src/$GO_IMPORT_PATH"
    local dirPath="$(dirname $importPath)"

    rm -rf $importPath
    mkdir -p $dirPath
    ln -s $PWD $importPath

    cd $importPath
  fi
}

unset_go_import_path() {
  if [ -n "$GO_IMPORT_PATH" ]
  then
    unlink $GOPATH/src/$GO_IMPORT_PATH
  fi
}
