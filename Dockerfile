FROM ubuntu:14.04

MAINTAINER Netlify

################################################################################
#
# Dependencies
#
################################################################################

RUN apt-get -y update && \
    apt-get install -y git-core build-essential g++ libssl-dev curl wget zip \
                      apache2-utils libxml2-dev libxslt-dev python-setuptools \
                      mercurial bzr imagemagick graphicsmagick libmagickwand-dev python2.7-dev \
                      advancecomp gifsicle jpegoptim libjpeg-progs optipng libgif-dev \
                      pngcrush fontconfig fontconfig-config libfontconfig1 \
                      gawk libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 \
                      autoconf libgdbm-dev libncurses5-dev automake bison libffi-dev \
                      gobject-introspection gtk-doc-tools libglib2.0-dev \
                      libjpeg-turbo8-dev libpng12-dev libwebp-dev libtiff5-dev \
                      pandoc libsm6 libxrender1 libfontconfig1 libgmp3-dev \
                      libexif-dev swig python3 python3-dev libgd-dev default-jdk \
                      php5-cli php5-cgi libmcrypt-dev && \
    apt-get clean

RUN curl -sSOL https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh && \
	bash script.deb.sh && \
	rm script.deb.sh && \
	apt-get install -y git-lfs

################################################################################
#
# Libvips
#
################################################################################

WORKDIR /tmp
ENV LIBVIPS_VERSION_MAJOR 7
ENV LIBVIPS_VERSION_MINOR 42
ENV LIBVIPS_VERSION_PATCH 3
ENV LIBVIPS_VERSION $LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR.$LIBVIPS_VERSION_PATCH
RUN \
  curl -O http://www.vips.ecs.soton.ac.uk/supported/$LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR/vips-$LIBVIPS_VERSION.tar.gz && \
  tar zvxf vips-$LIBVIPS_VERSION.tar.gz && \
  cd vips-$LIBVIPS_VERSION && \
  ./configure --enable-debug=no --enable-docs=no --without-python --without-orc --without-fftw --without-gsf $1 && \
  make && \
  make install && \
  ldconfig

WORKDIR /

################################################################################
#
# Locale and UTF-8
#
################################################################################

# Set a default language
RUN echo 'Acquire::Languages {"none";};' > /etc/apt/apt.conf.d/60language && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
    locale-gen en_US.UTF-8 && update-locale en_US.UTF-8

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

################################################################################
#
# User
#
################################################################################

RUN adduser --system --disabled-password --uid 2500 --quiet buildbot --home /opt/buildhome

################################################################################
#
# Ruby
#
################################################################################

USER buildbot
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys D39DC0E3 && \
    curl -L https://get.rvm.io | bash -s stable --with-gems="bundler" --autolibs=read-fail

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /bin/bash -c "source ~/.rvm/scripts/rvm && \
                  rvm install 2.0.0-p247 && rvm use 2.0.0-p247 && gem install bundler && \
                  rvm install 2.1.2 && rvm use 2.1.2 && gem install bundler && \
                  rvm install 2.2.1 && rvm use 2.2.1 && gem install bundler && \
                  rvm install 2.2.3 && rvm use 2.2.3 && gem install bundler && \
                  rvm install 2.3.0 && rvm use 2.3.0 && gem install bundler && \
                  rvm install 2.3.1 && rvm use 2.3.1 && gem install bundler && \
                  rvm use 2.1.2 --default && rvm cleanup all"

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER root

################################################################################
#
# Node.js
#
################################################################################

# Install node.js
USER buildbot
RUN git clone https://github.com/creationix/nvm.git ~/.nvm

RUN /bin/bash -c ". ~/.nvm/nvm.sh && \
		  nvm install 4 && nvm use 4 && npm install -g sm grunt-cli bower elm yarn && \
		  nvm install 6 && nvm use 6 && npm install -g sm grunt-cli bower elm yarn && \
		  nvm alias default node && nvm cache clear"

USER root

################################################################################
#
# Python
#
################################################################################

RUN easy_install virtualenv

USER buildbot

RUN virtualenv -p python2.7 --no-site-packages /opt/buildhome/python2.7 && \
    /bin/bash -c 'source /opt/buildhome/python2.7/bin/activate' && \
    ln -nfs /opt/buildhome/python2.7 /opt/buildhome/python2.7.4

RUN virtualenv -p python3.4 --no-site-packages /opt/buildhome/python3.4 && \
    /bin/bash -c 'source /opt/buildhome/python3.4/bin/activate' && \
    ln -nfs /opt/buildhome/python3.4.0 /opt/buildhome/python3.4.0

USER root


################################################################################
#
# Hugo
#
################################################################################

RUN mkdir /opt/hugo && cd /opt/hugo && \
    curl -L https://github.com/spf13/hugo/releases/download/v0.13/hugo_0.13_linux_amd64.tar.gz | tar zxvf - && \
    ln -s /opt/hugo/hugo_0.13_linux_amd64/hugo_0.13_linux_amd64 /usr/local/bin/hugo_0.13 && \
    curl -L https://github.com/spf13/hugo/releases/download/v0.14/hugo_0.14_linux_amd64.tar.gz | tar zxvf - && \
    ln -s /opt/hugo/hugo_0.14_linux_amd64/hugo_0.14_linux_amd64 /usr/local/bin/hugo_0.14 && \
    curl -L https://github.com/spf13/hugo/releases/download/v0.15/hugo_0.15_linux_amd64.tar.gz | tar zxvf - && \
    ln -s /opt/hugo/hugo_0.15_linux_amd64/hugo_0.15_linux_amd64 /usr/local/bin/hugo_0.15 && \
    mkdir /opt/hugo/hugo_0.16 && cd /opt/hugo/hugo_0.16 && \
    curl -L https://github.com/spf13/hugo/releases/download/v0.16/hugo_0.16_linux-64bit.tgz | tar zxvf - && \
    ln -s /opt/hugo/hugo_0.16/hugo /usr/local/bin/hugo_0.16 && \
    mkdir /opt/hugo/hugo_0.17 && cd /opt/hugo/hugo_0.17 && \
    curl -L https://github.com/spf13/hugo/releases/download/v0.17/hugo_0.17_Linux-64bit.tar.gz  | tar zxvf - && \
    ln -s /opt/hugo/hugo_0.17/hugo_0.17_linux_amd64/hugo_0.17_linux_amd64 /opt/hugo/hugo_0.17/hugo  && \
    ln -s /opt/hugo/hugo_0.17/hugo /usr/local/bin/hugo_0.17 && \
    ln -s /opt/hugo/hugo_0.17/hugo /usr/local/bin/hugo

################################################################################
#
# Clojure
#
################################################################################

RUN mkdir /opt/leiningen && cd /opt/leiningen && \
    curl -L https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > lein && \
    chmod +x lein && \
    ln -s /opt/leiningen/lein /usr/local/bin/lein

RUN mkdir /opt/boot-clj && cd /opt/boot-clj && \
    curl -L https://github.com/boot-clj/boot-bin/releases/download/2.4.2/boot.sh > boot && \
    chmod +x boot && \
    ln -s /opt/boot-clj/lein /usr/local/bin/boot

USER buildbot

RUN lein

################################################################################
#
# PHP
#
################################################################################

USER root

RUN cd /usr/local/bin && curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew && \
    chmod a+x phpbrew

USER buildbot

RUN /bin/bash -c 'phpbrew init && source ~/.phpbrew/bashrc && phpbrew install 5.6 +default && \
    phpbrew app get composer'

USER root

# Cleanup
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && apt-get autoremove -y

# Add buildscript for local testing
ADD run-build.sh /usr/local/bin/build
ADD buildbot-git-config /opt/buildhome/.gitconfig

USER buildbot
