#!/bin/bash
# helper to check if we need to install deps
# install_deps configuration_file version shasum_file

if [ $NETLIFY_VERBOSE ]
then
  set -x
fi

export NVM_DIR="$HOME/.nvm"
export RVM_DIR="$HOME/.rvm"

YELLOW=`tput setaf 3`
NC=`tput sgr0` # No Color

mkdir -p $NETLIFY_CACHE_DIR/node_version
mkdir -p $NETLIFY_CACHE_DIR/node_modules
mkdir -p $NETLIFY_CACHE_DIR/.yarn_cache
mkdir -p $NETLIFY_CACHE_DIR/ruby_version
mkdir -p $NETLIFY_CACHE_DIR/.bundle
mkdir -p $NETLIFY_CACHE_DIR/bower_components
mkdir -p $NETLIFY_CACHE_DIR/.cache
mkdir -p $NETLIFY_CACHE_DIR/.cask
mkdir -p $NETLIFY_CACHE_DIR/.emacs.d
mkdir -p $NETLIFY_CACHE_DIR/.m2
mkdir -p $NETLIFY_CACHE_DIR/.boot

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
  if [ -d $NETLIFY_CACHE_DIR/.yarn_cache ]
  then
    rm -rf $NETLIFY_BUILD_BASE/.yarn_cache
    mv $NETLIFY_CACHE_DIR/.yarn_cache $NETLIFY_BUILD_BASE/.yarn_cache
  fi

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

  if yarn install --cache-folder $NETLIFY_BUILD_BASE/.yarn_cache "$yarn_local"
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
    if npm install "$NPM_FLAGS"; then
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

  # Python Version
  if [ -f runtime.txt ]
  then
    if source $HOME/python$(cat runtime.txt)/bin/activate
    then
      echo "Python version set to $(cat runtime.txt)"
    else
      echo "Error setting python version from runtime.txt"
      echo "Will use default version (2.7)"
      source $HOME/python2.7/bin/activate
    fi
  else
    source $HOME/python2.7/bin/activate
  fi

  # Node version
  source $NVM_DIR/nvm.sh
  : ${NODE_VERSION="$defaultNodeVersion"}

  # restore only non-existing cached versions
  if [ $(ls $NETLIFY_CACHE_DIR/node_version/) ]
  then
    rm -rf $NVM_DIR/versions/node/*
    cp -p -r $NETLIFY_CACHE_DIR/node_version/* $NVM_DIR/versions/node/
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
    echo "Using version $NODE_VERSION of node"
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
  source $HOME/.rvm/scripts/rvm
  # rvm will overwrite RUBY_VERSION, so we must control it
  RUBY_VERSION="$defaultRubyVersion"
  export RUBY_VERSION

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
    rm -rf $RVM_DIR/rubies/${fulldruby}
    cp -p -r $NETLIFY_CACHE_DIR/ruby_version/${fulldruby} $RVM_DIR/rubies/
  fi

  rvm --create use ${druby} > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    local crv=$(rvm current)
    export RUBY_VERSION=${crv#ruby-}
    echo "Using ruby version ${RUBY_VERSION}"
  else
    echo -e "${YELLOW}"
    echo -e "** WARNING **"
    echo -e "Using custom ruby version ${druby}, this will slow down the build."
    echo -e "To ensure fast builds, set the RUBY_VERSION environment variable, or .ruby-version file, to an included ruby version."
    echo -e "Included versions: ${rvs[@]#ruby-}"
    echo -e "${NC}"
    if rvm_install_on_use_flag=1 rvm --create use ${druby}
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

  # Rubygems
  if [ -f Gemfile ]
  then
    # Make sure no existing .bundle/config is around
    rm -rf .bundle
    if [ -d $NETLIFY_CACHE_DIR/.bundle ];
    then
      mv $NETLIFY_CACHE_DIR/.bundle .bundle
    fi
    if install_deps Gemfile.lock $RUBY_VERSION $NETLIFY_CACHE_DIR/gemfile-sha || [ ! -d .bundle ]
    then
      echo "Installing gem bundle"
      if bundle install --path $NETLIFY_CACHE_DIR/bundle --binstubs=$NETLIFY_CACHE_DIR/binstubs "$BUNDLER_FLAGS"
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
    if [ -d $NETLIFY_CACHE_DIR/.cache ]
    then
      rm -rf $NETLIFY_BUILD_BASE/.cache
      mv $NETLIFY_CACHE_DIR/.cache $NETLIFY_BUILD_BASE/.cache
    fi
    if pip install -r requirements.txt
    then
      echo "Pip dependencies installed"
    else
      echo "Error installing pip dependencies"
      exit 1
    fi
  fi

  # NPM Dependencies
  : ${YARN_VERSION="$defaultYarnVersion"}

  if [ -f package.json ]
  then
    if [ -d $NETLIFY_CACHE_DIR/node_modules ]
    then
        rm -rf $NETLIFY_REPO_DIR/node_modules
        mv $NETLIFY_CACHE_DIR/node_modules $NETLIFY_REPO_DIR/node_modules
    fi

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
    if [ -d $NETLIFY_CACHE_DIR/bower_components ]
    then
      rm -rf $NETLIFY_REPO_DIR/bower_components
        mv $NETLIFY_CACHE_DIR/bower_components $NETLIFY_REPO_DIR/bower_components
      fi

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
    if [ -d $NETLIFY_CACHE_DIR/.m2 ]
    then
      rm -rf $NETLIFY_BUILD_BASE/.m2
      mv $NETLIFY_CACHE_DIR/.m2 $NETLIFY_BUILD_BASE/.m2
    fi
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
    if [ -d $NETLIFY_CACHE_DIR/.m2 ]
    then
      rm -rf $NETLIFY_BUILD_BASE/.m2
      mv $NETLIFY_CACHE_DIR/.m2 $NETLIFY_BUILD_BASE/.m2
    fi
    if [ -d $NETLIFY_CACHE_DIR/.boot ]
    then
      rm -rf $NETLIFY_BUILD_BASE/.boot
      mv $NETLIFY_CACHE_DIR/.boot $NETLIFY_BUILD_BASE/.boot
    fi
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
    if [ -d $NETLIFY_CACHE_DIR/.cask ]
    then
      rm -rf $NETLIFY_BUILD_BASE/.cask
      mv $NETLIFY_CACHE_DIR/.cask $NETLIFY_BUILD_BASE/.cask
    fi

    if [ -d $NETLIFY_CACHE_DIR/.emacs.d ]
    then
      rm -rf $NETLIFY_BUILD_BASE/.emacs.d
      mv $NETLIFY_CACHE_DIR/.emacs.d $NETLIFY_BUILD_BASE/.emacs.d
    fi

    if cask install
    then
      echo "Emacs packages installed"
    fi
  fi
}

#
# Take things installed during the build and cache them
#
cache_artifacts() {
  if [ -d .bundle ]
  then
    rm -rf $NETLIFY_CACHE_DIR/.bundle
    mv .bundle $NETLIFY_CACHE_DIR/.bundle
    echo "Cached ruby gems"
  fi

  if [ -d bower_components ]
  then
    rm -rf $NETLIFY_CACHE_DIR/bower_components
    mv bower_components $NETLIFY_CACHE_DIR/bower_components
    echo "Cached bower components"
  fi

  if [ -d node_modules ]
  then
    rm -rf $NETLIFY_CACHE_DIR/node_modules
    mv node_modules $NETLIFY_CACHE_DIR/node_modules
    echo "Cached NPM modules"
  fi

  if [ -d $NETLIFY_BUILD_BASE/.yarn_cache ]
  then
    rm -rf $NETLIFY_CACHE_DIR/.yarn_cache
    mv $NETLIFY_BUILD_BASE/.yarn_cache $NETLIFY_CACHE_DIR/.yarn_cache
    echo "Saved Yarn cache"
  fi

  if [ -d $NETLIFY_BUILD_BASE/.cache ]
  then
    rm -rf $NETLIFY_CACHE_DIR/.cache
    mv $NETLIFY_BUILD_BASE/.cache $NETLIFY_CACHE_DIR/.cache
    echo "Saved pip cache Directory"
  fi

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

  if [ -d .cask ]
  then
    mv $NETLIFY_BUILD_BASE/.cask $NETLIFY_CACHE_DIR/.cask
    echo "Cached Emacs Cask dependencies"
  fi

  if [ -d $NETLIFY_BUILD_BASE/.emacs.d ]
  then
    rm -rf $NETLIFY_CACHE_DIR/.emacs.d
    mv $NETLIFY_BUILD_BASE/.emacs.d $NETLIFY_CACHE_DIR/.emacs.d
    echo "Saved Emacs cache"
  fi

  if [ -d $NETLIFY_BUILD_BASE/.m2 ]
  then
    rm -rf $NETLIFY_CACHE_DIR/.m2
    mv $NETLIFY_BUILD_BASE/.m2 $NETLIFY_CACHE_DIR/.m2
    echo "Cached Maven dependencies"
  fi

  if [ -d $NETLIFY_BUILD_BASE/.boot ]
  then
    rm -rf $NETLIFY_CACHE_DIR/.boot
    mv $NETLIFY_BUILD_BASE/.boot $NETLIFY_CACHE_DIR/.boot
    echo "Cached Boot dependencies"
  fi
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
