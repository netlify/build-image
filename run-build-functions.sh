#!/bin/bash
# helper to heck if we need to install deps
# install_deps configuration_file version shasum_file

if [ $NETLIFY_VERBOSE ]
then
  set -x
fi

NVM_DIR="$HOME/.nvm"

mkdir -p $NETLIFY_CACHE_DIR/node_version
mkdir -p $NETLIFY_CACHE_DIR/node_modules
mkdir -p $NETLIFY_CACHE_DIR/.yarn_cache
mkdir -p $NETLIFY_CACHE_DIR/.bundle
mkdir -p $NETLIFY_CACHE_DIR/bower_components
mkdir -p $NETLIFY_CACHE_DIR/.cache

: ${YARN_FLAGS="--ignore-optional"}

install_deps() {
  if [ ! -f $1 ]
  then
    return 0
  fi
  if [ ! -f $3 ]
  then
     return 0
  fi
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

  if [ $(which yarn) ] && ! [ "$(yarn --version)" == "$yarn_version" ]
  then
    echo "Found yarn version ($(yarn --version)) that doesn't match expected ($yarn_version)"
    rm -rf $NETLIFY_CACHE_DIR/yarn $HOME/.yarn
    npm uninstall yarn -g
  fi

  if ! [ $(which yarn) ]
  then
    echo "Installing yarn at version $yarn_version"
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
  if install_deps package.json $NODE_VERSION $NETLIFY_CACHE_DIR/package-sha
  then
    echo "Installing NPM modules"
    run_npm_set_temp
    if npm install; then
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
    nvm install $(cat .nvmrc) > /dev/null
    if [ $? -ne 0 ]
    then
      echo "Failed to set version of node to '$(cat .nvmrc)' from .nvmrc. Falling back to $NODE_VERSION."
      nvm install $NODE_VERSION
    else
      NODE_VERSION=$(nvm current)
    fi
  else
    nvm install  $NODE_VERSION
    NODE_VERSION=$(nvm current)
  fi
  echo "Using version $NODE_VERSION of node"
  export NODE_VERSION=$NODE_VERSION

  if [ -n "$NPM_TOKEN" ]
  then
    if [ ! -f .npmrc ]
    then
      echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > .npmrc
    fi
  fi

  # Ruby version
  source $HOME/.rvm/scripts/rvm
  : ${RUBY_VERSION="$defaultRubyVersion"}
  export RUBY_VERSION

  if [ -f .ruby-version ]
  then
    if rvm use $(cat .ruby-version)
    then
      echo "Set ruby from .ruby-version"
      export RUBY_VERSION=$(cat .ruby-version)
    else
      echo "Error setting ruby version from .ruby-version file. Unsupported version?"
      echo "Will use default version ($RUBY_VERSION)"
      rvm use $RUBY_VERSION
    fi
  else
    rvm use $RUBY_VERSION
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
      if bundle install --path $NETLIFY_CACHE_DIR/bundle --binstubs=$NETLIFY_CACHE_DIR/binstubs
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
      rm -rf $NETLIFY_REPO_DIR/.cache
      mv $NETLIFY_CACHE_DIR/.cache $NETLIFY_REPO_DIR/.cache
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
    mkdir -p $NETLIFY_CACHE_DIR/m2
    ln -nfs $NETLIFY_CACHE_DIR/m2 ~/.m2
    if install_deps project.clj $JAVA_VERSION $NETLIFY_CACHE_DIR/project-clj-sha
    then
      echo "Installing leiningen dependencies"
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
    mkdir -p $NETLIFY_CACHE_DIR/m2
    ln -nfs $NETLIFY_CACHE_DIR/m2 ~/.m2
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
    hugoPath=$(binrc install -c $NETLIFY_CACHE_DIR/.binrc hugo)
    if [ $? -eq 0 ]
    then
      export PATH=$(dirname $hugoPath):$PATH
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

  if [ -d .cache ]
  then
    rm -rf $NETLIFY_CACHE_DIR/.cache
    mv .yarn_cache $NETLIFY_CACHE_DIR/.cache
    echo "Saved Pip cache"
  fi

  # cache the version of node installed
  if ! [ -d $NETLIFY_CACHE_DIR/node_version/$NODE_VERSION ]
  then
    rm -rf $NETLIFY_CACHE_DIR/node_version
    mkdir $NETLIFY_CACHE_DIR/node_version
    mv $NVM_DIR/versions/node/$NODE_VERSION $NETLIFY_CACHE_DIR/node_version/
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
