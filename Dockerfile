FROM ubuntu:14.04

MAINTAINER Netlify

RUN apt-get -y update && \
    apt-get install -y git-core build-essential g++ libssl-dev curl wget \
                      apache2-utils libxml2-dev libxslt-dev python-setuptools \
                      mercurial bzr imagemagick libmagickwand-dev python2.7-dev \
                      advancecomp gifsicle jpegoptim libjpeg-progs optipng \
                      pngcrush fontconfig fontconfig-config libfontconfig1 && \
    apt-get clean


# Set a default language
RUN echo 'Acquire::Languages {"none";};' > /etc/apt/apt.conf.d/60language && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
    locale-gen en_US.UTF-8 && update-locale en_US.UTF-8

# Prepare user and homedir
RUN adduser --system --disabled-password --uid 2500 --quiet buildbot --home /opt/buildhome

################################################################################
#
# Ruby
#
################################################################################

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 && \
    curl -L https://get.rvm.io | bash -s stable

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /usr/local/rvm/bin/rvm-shell && rvm requirements && \
    rvm install 2.1.2 && rvm install 2.2.1 && \
    rvm use 2.2.1 --default && rvm cleanup all

ENV PATH /usr/local/rvm/rubies/ruby-2.2.1/bin:/usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN gem install bundler


################################################################################
#
# Node.js
#
################################################################################

RUN git clone https://github.com/creationix/nvm.git /.nvm && \
    echo ". /.nvm/nvm.sh" >> /etc/bash.bashrc

# Install node.js
RUN /bin/bash -c '. /.nvm/nvm.sh && nvm install v0.10.29 && nvm use v0.10.29 && \
    nvm alias default v0.10.29 && ln -s /.nvm/v0.10.29/bin/node /usr/bin/node && \
    ln -s /.nvm/v0.10.29/bin/npm /usr/bin/npm' && \
    npm install -g sm && npm install -g grunt-cli && npm install -g bower


################################################################################
#
# Python
#
################################################################################

RUN easy_install virtualenv && \
    virtualenv -p python2.7 --no-site-packages /opt/buildhome/python2.7 && \
    /bin/bash -c 'source /opt/buildhome/python2.7/bin/activate && easy_install pip'


################################################################################
#
# User
#
################################################################################


# Cleanup
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER buildbot
