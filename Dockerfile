FROM ubuntu:14.04

MAINTAINER BitBalloon

RUN apt-get -y update
RUN apt-get install -y git-core build-essential g++ libssl-dev curl wget apache2-utils libxml2-dev python-setuptools


################################################################################
#
# Ruby
#
################################################################################

RUN curl -L https://get.rvm.io | bash -s stable

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /usr/local/rvm/bin/rvm-shell && rvm requirements
RUN /usr/local/rvm/bin/rvm-shell && rvm install 2.1.2
RUN /usr/local/rvm/bin/rvm-shell && rvm use 2.1.2 --default

ENV PATH /usr/local/rvm/rubies/ruby-2.1.2/bin:/usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN gem install bundler


################################################################################
#
# Node.js
#
################################################################################

RUN git clone https://github.com/creationix/nvm.git /.nvm
RUN echo ". /.nvm/nvm.sh" >> /etc/bash.bashrc

# Install node.js
RUN /bin/bash -c '. /.nvm/nvm.sh && nvm install v0.10.29 && nvm use v0.10.29 && nvm alias default v0.10.29 && ln -s /.nvm/v0.10.29/bin/node /usr/bin/node && ln -s /.nvm/v0.10.29/bin/npm /usr/bin/npm'

RUN npm install -g sm
RUN npm install -g grunt-cli
RUN npm install -g bower


################################################################################
#
# Python
#
################################################################################

RUN easy_install virtualenv
RUN virtualenv -p python2.7.3 --no-site-packages /usr/local/python2.7.3


################################################################################
#
# User
#
################################################################################

RUN adduser --system --disabled-password --uid 2500 --quiet buildbot

USER buildbot
