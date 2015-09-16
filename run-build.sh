#!/bin/bash

export CMD=$*

if [ -z "$CMD" ]; then
  echo "Usage: $0 <your build cmd>"
  exit 1
fi

set -e

cd /opt/buildhome
if [ ! -d repo ]; then
  git clone /opt/repo repo
else
  cd repo
fi

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
source /.nvm/nvm.sh
export NODE_VERSION=0.12.2
if [ -f .nvmrc ]
then
	if nvm use; then
		echo "Set node from .nvmrc"
		export NODE_VERSION=$(cat .nvmrc)
	else
		echo "Error setting node version from .nvmrc file. Unsupported version?"
		echo "Will use default version ($NODE_VERSION)"
	fi
fi

# Ruby version
source $HOME/.rvm/scripts/rvm
export RUBY_VERSION=2.1.2
if [ -f .ruby-version ]
then
	if rvm use $(cat .ruby-version); then
		echo "Set ruby from .ruby-version"
		export RUBY_VERSION=$(cat .ruby-version)
	else
		echo "Error setting ruby version from .ruby-version file. Unsupported version?"
		echo "Will use default version (2.1.2)"
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
  echo "Installing gem bundle"
  if bundle install --path /opt/build/cache/bundle --deployment --binstubs=/opt/build/cache/binstubs; then
  	export PATH=/opt/build/cache/binstubs:$PATH
		echo "Gem bundle installed"
	fi
fi

# PIP dependencies
if [ -f requirements.txt ]
then
	echo "Installing pip dependencies"
	if pip install -r requirements.txt; then
		echo "Pip dependencies installed"
	fi
fi

# NPM Dependencies
if [ -f package.json ]
then
  echo "Installing npm modules"
  if npm install; then
  	export PATH=$(npm bin):$PATH
		echo "NPM modules installed"
	fi
fi

# Bower Dependencies
if [ -f bower.json ]
then
  echo "Installing bower components"
  if bower install --config.interactive=false; then
		echo "Bower components installed"
	fi
fi

# Leiningen
if [ -f project.clj ]
then
  if lein deps; then
		echo "Leiningen dependencies installed"
	fi
fi

echo "Running build command '$CMD'"
eval $CMD
