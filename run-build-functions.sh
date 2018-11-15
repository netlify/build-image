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

# Pipenv configuration
export PIPENV_RUNTIME=2.7
export PIPENV_VENV_IN_PROJECT=1
export PIPENV_DEFAULT_PYTHON_VERSION=2.7

YELLOW="\033[0;33m"
NC="\033[0m" # No Color

# language versions
mkdir -p $NETLIFY_CACHE_DIR/node_version
mkdir -p $NETLIFY_CACHE_DIR/ruby_version

# pwd caches
mkdir -p $NETLIFY_CACHE_DIR/node_modules
mkdir -p $NETLIFY_CACHE_DIR/.bundle
mkdir -p $NETLIFY_CACHE_DIR/bower_components
mkdir -p $NETLIFY_CACHE_DIR/.venv

# HOME caches
mkdir -p $NETLIFY_CACHE_DIR/.yarn_cache
mkdir -p $NETLIFY_CACHE_DIR/.cache
mkdir -p $NETLIFY_CACHE_DIR/.cask
mkdir -p $NETLIFY_CACHE_DIR/.emacs.d
mkdir -p $NETLIFY_CACHE_DIR/.m2
mkdir -p $NETLIFY_CACHE_DIR/.boot
mkdir -p $NETLIFY_CACHE_DIR/.composer
mkdir -p $NETLIFY_CACHE_DIR/.gimme_cache/gopath
mkdir -p $NETLIFY_CACHE_DIR/.gimme_cache/gocache

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

install_dependencies() {
  local defaultNodeVersion=$1
  local defaultRubyVersion=$2
  local defaultYarnVersion=$3
  local defaultPHPVersion=$4
  local installGoVersion=$5

  # Python Version
  if [ -f runtime.txt ]
  then
    PYTHON_VERSION=$(cat runtime.txt)
    if source $HOME/python${PYTHON_VERSION}/bin/activate
    then
      echo "Python version set to ${PYTHON_VERSION}"
    else
      echo "Error setting python version from runtime.txt"
      echo "Please see https://github.com/netlify/build-image/#included-software for current versions"
      exit 1
    fi
  elif [ -f Pipfile ]
  then
    echo "Found Pipfile restoring Pipenv virtualenv"
    restore_cwd_cache ".venv" "python virtualenv"
  else
    source $HOME/python2.7/bin/activate
  fi

  # Node version
  source $NVM_DIR/nvm.sh
  : ${NODE_VERSION="$defaultNodeVersion"}

  # restore only non-existing cached versions
  if [ $(ls $NETLIFY_CACHE_DIR/node_version/) ]
  then
    echo "Started restoring cached node version"
    rm -rf $NVM_DIR/versions/node/*
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

  if nvm install $NODE_VERSION
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
    echo -e "${YELLOW}"
    echo "** WARNING **"
    echo "Using custom ruby version ${druby}, this will slow down the build."
    echo "To ensure fast builds, set the RUBY_VERSION environment variable, or .ruby-version file, to an included ruby version."
    echo "Included versions: ${rvs[@]#ruby-}"
    echo -e "${NC}"
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
  
  if ! gem list -i "^bundler$" > /dev/null 2>&1
  then
    if ! gem install bundler
    then
      echo "Error installing bundler"
      exit 1
    fi
  fi

  # Java version
  export JAVA_VERSION=default_sdk

  # PHP version
  : ${PHP_VERSION="$defaultPHPVersion"}
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
      echo "Installing gem bundle"
      if bundle install --path $NETLIFY_CACHE_DIR/bundle --binstubs=$NETLIFY_CACHE_DIR/binstubs ${BUNDLER_FLAGS:+"$BUNDLER_FLAGS"}
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
    restore_home_cache ".cache" "pip cache"
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

  # NPM Dependencies
  : ${YARN_VERSION="$defaultYarnVersion"}

  if [ -f package.json ]
  then
    restore_cwd_cache node_modules "node modules"
    if [ -f yarn.lock ]
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
      npm install bower
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
    hugoOut=$(binrc install -c $NETLIFY_CACHE_DIR/.binrc hugo)
    if [ $? -eq 0 ]
    then
      export PATH=$(dirname $hugoOut):$PATH
    else
      echo "Error during Hugo $HUGO_VERSION install: $hugoOut"
      exit 1
    fi
  fi

  # Gutenberg
  if [ -n "$GUTENBERG_VERSION" ]
  then
    echo "Installing Gutenberg $GUTENBERG_VERSION"
    gutenbergOut=$(binrc install -c $NETLIFY_CACHE_DIR/.binrc gutenberg)
    if [ $? -eq 0 ]
    then
      export PATH=$(dirname $gutenbergOut):$PATH
    else
      echo "Error during Gutenberg $GUTENBERG_VERSION install: $gutenbergOut"
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
    gimme
    if [ $? -eq 0 ]
    then
      source $HOME/.gimme/env/go$GIMME_GO_VERSION.linux.amd64.env
    else
      echo "Failed to install Go version '$GIMME_GO_VERSION'"
      exit 1
    fi
  fi

  # Setup project GOPATH
  if [ -n "$GO_IMPORT_PATH" ]
  then
    mkdir -p "$(dirname $GOPATH/src/$GO_IMPORT_PATH)"
    rm -rf $GOPATH/src/$GO_IMPORT_PATH
    ln -s /opt/buildhome/repo ${GOPATH}/src/$GO_IMPORT_PATH
  fi
}

#
# Take things installed during the build and cache them
#
cache_artifacts() {
  cache_cwd_directory ".bundle" "ruby gems"
  cache_cwd_directory "bower_components" "bower components"
  cache_cwd_directory "node_modules" "node modules"
  cache_cwd_directory ".venv" "python virtualenv"

  cache_home_directory ".yarn_cache" "yarn cache"
  cache_home_directory ".cache" "pip cache"
  cache_home_directory ".cask" "emacs cask dependencies"
  cache_home_directory ".emacs.d" "emacs cache"
  cache_home_directory ".m2" "maven dependencies"
  cache_home_directory ".boot" "boot dependencies"
  cache_home_directory ".composer" "composer dependencies"


  # Don't follow the Go import path or we'll store
  # the origin repo twice.
  if [ -n "$GO_IMPORT_PATH" ]
  then
    unlink $GOPATH/src/$GO_IMPORT_PATH
  fi
  cache_home_directory ".gimme_cache" "go dependencies"

  # cache the version of node installed
  if ! [ -d $NETLIFY_CACHE_DIR/node_version/$NODE_VERSION ]
  then
    rm -rf $NETLIFY_CACHE_DIR/node_version
    mkdir $NETLIFY_CACHE_DIR/node_version
    mv $NVM_DIR/versions/node/$NODE_VERSION $NETLIFY_CACHE_DIR/node_version/
    echo "Cached node version $NODE_VERSION"
  fi

  # cache the version of ruby installed
  if [ "$CUSTOM_RUBY" -ne "0" ]
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
}

move_cache() {
  local src=$1
  local dst=$2
  if [ -d $src ]
  then
    echo "Started $3"
    rm -rf $dst
    mv $src $dst
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

cache_cwd_directory() {
  move_cache "$PWD/$1" "$NETLIFY_CACHE_DIR/$1" "saving $2"
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

    rm -rf $dirPath
    mkdir -p $dirPath
    ln -s $PWD $importPath

    cd $importPath
  fi
}

find_running_procs() {
  ps aux | grep -v [p]s | grep -v [g]rep | grep -v [b]ash
}

report_lingering_procs() {
  procs=$(find_running_procs)
  nprocs=$(expr $(echo "$procs" | wc -l) - 1)
  if [[ $nprocs > 0 ]]; then
    echo -e "${YELLOW}"
    echo "** WARNING **"
    echo "There are some lingering processes even after the build process finished: "
    echo
    echo "$procs"
    echo
    echo "Our builds do not kill your processes automatically, so please make sure"
    echo "that nothing is running after your build finishes, or it will be marked as"
    echo "failed since something is still running."
    echo -e "${NC}"
  fi
}

after_build_steps() {
  echo "Caching artifacts"
  cache_artifacts

  # Find lingering processes after the build finished and report it to the user
  report_lingering_procs
}
