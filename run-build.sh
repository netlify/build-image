#!/bin/bash

export CMD=$*

if [[ -z "$CMD" ]]; then
  echo "Usage: $0 <your build cmd>"
  exit 1
fi

set -e

cd /opt/buildhome
if [[ ! -d repo ]]; then
  git clone /opt/repo repo
fi
cd repo

if [[ -f runtime.txt ]]; then
	if source $HOME/python$(cat runtime.txt)/bin/activate; then
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
source $HOME/.nvm/nvm.sh
export NODE_VERSION=6
if [[ -f .nvmrc ]]; then
  nvm install $(cat .nvmrc)
  if [[ $? -ne 0 ]]; then
    echo "Failed to set version of node to '$(cat .nvmrc)' from .nvmrc. Falling back to version $NODE_VERSION"
  else
    NODE_VERSION=$(nvm current)
  fi
fi
export NODE_VERSION=$NODE_VERSION

# Ruby version
source $HOME/.rvm/scripts/rvm
export RUBY_VERSION=2.2.7
if [[ -f .ruby-version ]]; then
	desired_ruby_version=$(cat .ruby-version)
	if rvm use "$desired_ruby_version" --install --binary --fuzzy; then
		echo "Using Ruby ${desired_ruby_version} specified in .ruby-version"
		export RUBY_VERSION="$desired_ruby_version"
	else
		echo "Failed to install/use Ruby ${desired_ruby_version} specified in .ruby-version"
		echo "Will use default version (${RUBY_VERSION})"
		rvm use $RUBY_VERSION
	fi
else
	rvm use $RUBY_VERSION
fi

# Java version
export JAVA_VERSION=default_sdk

# Rubygems
if [[ -f Gemfile ]]; then
  echo "Installing gem bundle"
  if bundle install --path $HOME/bundle --deployment --binstubs=$HOME/binstubs; then
		export PATH=$HOME/binstubs:$PATH
		echo "Gem bundle installed"
	fi
fi

# PIP dependencies
if [[ -f requirements.txt ]]; then
	echo "Installing pip dependencies"
	if pip install -r requirements.txt; then
		echo "Pip dependencies installed"
	fi
fi

# NPM Dependencies
if [[ -f package.json ]]; then
	echo "Installing npm modules"
	if [[ -f yarn.lock ]]; then
		if yarn install; then
			export PATH=$(yarn bin):$PATH
			echo "NPM modules installed"
		fi
	else
		if npm install; then
			export PATH=$(npm bin):$PATH
			echo "NPM modules installed"
		fi
	fi
fi

# Bower Dependencies
if [[ -f bower.json ]]; then
	echo "Installing bower components"
	if bower install --config.interactive=false; then
		echo "Bower components installed"
	fi
fi

# Leiningen
if [[ -f project.clj ]]; then
  if lein deps; then
		echo "Leiningen dependencies installed"
	fi
fi

echo "Running build command '$CMD'"
eval $CMD
