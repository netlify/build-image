FROM ubuntu:14.04

MAINTAINER BitBalloon

RUN apt-get -y update
RUN apt-get install -y git-core build-essential g++ libssl-dev curl wget apache2-utils libxml2-dev libxslt-dev python-setuptools mercurial bzr imagemagick


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


################################################################################
#
# Go
#
################################################################################

RUN curl -s https://go.googlecode.com/files/go1.2.src.tar.gz | tar -v -C /usr/local -xz
RUN cd /usr/local/go/src && ./make.bash --no-clean 2>&1
ENV PATH /usr/local/go/bin:/go/bin:$PATH
ENV GOPATH /go

# we're using godep to save / restore dependancies
RUN go get github.com/kr/godep
RUN go get github.com/spf13/hugo

# Hugo install doesn't seem to install bin
# RUN curl -L https://github.com/spf13/hugo/releases/download/v0.11/hugo_0.11_linux_386.tar.gz | tar xvfz -C /usr/local


################################################################################
#
# User
#
################################################################################


RUN adduser --system --disabled-password --uid 2500 --quiet buildbot --home /opt/buildhome

USER buildbot


################################################################################
#
# Python for buildbot user
#
################################################################################

RUN virtualenv -p python2.7 --no-site-packages /opt/buildhome/python2.7
RUN /bin/bash -c 'source /opt/buildhome/buildbot/python2.7/bin/activate && easy_install pip'
