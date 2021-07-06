FROM ubuntu:16.04

LABEL maintainer Netlify

################################################################################
#
# Dependencies
#
################################################################################

ENV LANGUAGE en_US:en
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PANDOC_VERSION 2.4

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends software-properties-common language-pack-en-base apt-transport-https gnupg-curl && \
    echo 'Acquire::Languages {"none";};' > /etc/apt/apt.conf.d/60language && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
    locale-gen en_US.UTF-8 && \
    update-locale en_US.UTF-8 && \
    apt-key adv --fetch-keys https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc && \
    apt-key adv --fetch-keys https://packagecloud.io/github/git-lfs/gpgkey && \
    apt-add-repository -y -s 'deb https://packagecloud.io/github/git-lfs/ubuntu/ xenial main' && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    add-apt-repository -y ppa:git-core/ppa && \
    add-apt-repository -y ppa:rwky/graphicsmagick && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    add-apt-repository -y ppa:kelleyk/emacs && \
    apt-add-repository -y 'deb https://packages.erlang-solutions.com/ubuntu xenial contrib' && \
    apt-get -y update && \
    apt-get install -y --no-install-recommends \
        advancecomp \
        apache2-utils \
        autoconf \
        automake \
        bison \
        build-essential \
        bzr \
        cmake \
        curl \
        doxygen \
        elixir \
        emacs25-nox \
        esl-erlang \
        expect \
        file \
        fontconfig \
        fontconfig-config \
        g++ \
        gawk \
        git \
        git-lfs \
        gifsicle \
        gobject-introspection \
        graphicsmagick \
        graphviz \
        gtk-doc-tools \
        gnupg2 \
        imagemagick \
        jpegoptim \
        jq \
        language-pack-ar \
        language-pack-ca \
        language-pack-cs \
        language-pack-da \
        language-pack-de \
        language-pack-el \
        language-pack-es \
        language-pack-eu \
        language-pack-fi \
        language-pack-fr \
        language-pack-gl \
        language-pack-he \
        language-pack-hi \
        language-pack-it \
        language-pack-ja \
        language-pack-ka \
        language-pack-ko \
        language-pack-nn \
        language-pack-pl \
        language-pack-pt \
        language-pack-ro \
        language-pack-ru \
        language-pack-sv \
        language-pack-ta \
        language-pack-th \
        language-pack-tr \
        language-pack-uk \
        language-pack-vi \
        language-pack-zh-hans \
        language-pack-zh-hant \
        libasound2 \
        libcurl3 \
        libcurl3-gnutls \
        libcurl3-openssl-dev \
        libenchant1c2a \
        libexif-dev \
        libffi-dev \
        libfontconfig1 \
        libgconf-2-4 \
        libgd-dev \
        libgdbm-dev \
        libgif-dev \
        libglib2.0-dev \
        libgmp3-dev \
        libgsl2 \
        libgsl-dev \
        libgtk-3-0 \
        libgtk2.0-0 \
        libicu-dev \
        libimage-exiftool-perl \
        libjpeg-progs \
        libjpeg-turbo8-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libncurses5-dev \
        libnss3 \
        libpng12-dev \
        libreadline6-dev \
        librsvg2-bin \
        libsm6 \
        libsqlite3-dev \
        libssl-dev \
        libtiff5-dev \
        libwebp-dev \
        libwebp5 \
        libxml2-dev \
        libxrender1 \
        libxslt-dev \
        libxss1 \
        libxtst6 \
        libyaml-dev \
        mercurial \
        nasm \
        openjdk-8-jdk \
        optipng \
        pngcrush \
        python-setuptools \
        python \
        python-dev \
        python3 \
        python3-dev \
        python3.7 \
        python3.7-dev \
        rlwrap \
        rsync \
        software-properties-common \
        sqlite3 \
        ssh \
        strace \
        swig \
        tree \
        unzip \
        virtualenv \
        wget \
        xfonts-base \
        xfonts-75dpi \
        xvfb \
        zip \
# dotnet core dependencies
	libunwind8-dev \
	libicu-dev \
	libcurl3 \
	liblttng-ust0 \
	libkrb5-3 \
        && \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get autoremove -y && \
    unset DEBIAN_FRONTEND


################################################################################
#
# Pandoc
#
################################################################################

RUN wget -nv https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.xenial_amd64.deb && \
    dpkg -i wkhtmltox_0.12.5-1.xenial_amd64.deb && \
    rm wkhtmltox_0.12.5-1.xenial_amd64.deb && \
    wkhtmltopdf -V

# install Pandoc (more recent version to what is provided in Ubuntu 14.04)
RUN wget https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb && \
    dpkg -i pandoc-$PANDOC_VERSION-1-amd64.deb && \
    rm pandoc-$PANDOC_VERSION-1-amd64.deb && \
    pandoc -v

################################################################################
#
# Libvips
#
################################################################################

WORKDIR /tmp

# this actually builds v8.6.2
RUN \
  curl -sLo vips-8.6.2.tar.gz https://github.com/jcupitt/libvips/archive/v8.6.2.tar.gz && \
  tar xvf vips-8.6.2.tar.gz && \
  cd libvips-8.6.2 && \
  ./autogen.sh && \
  ./configure --enable-debug=no --enable-docs=no --without-python --without-orc --without-fftw --without-gsf $1 && \
  make && \
  make install && \
  ldconfig


WORKDIR /

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

## TODO: Consider switching to rbenv or asdf-vm
USER buildbot
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import && \
    curl -sL https://get.rvm.io | bash -s stable --with-gems="bundler" --autolibs=read-fail

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Match this set latest Stable releases we can support on https://www.ruby-lang.org/en/downloads/
ENV RUBY_VERSION=2.7.2
# Also preinstall Ruby 2.6.2, as many customers are pinned to it and installing is slow
RUN /bin/bash -c "source ~/.rvm/scripts/rvm && \
                  rvm install 2.6.2 && rvm use 2.6.2 && gem install bundler && \
                  rvm install $RUBY_VERSION && rvm use $RUBY_VERSION && gem install bundler && \
                  rvm use $RUBY_VERSION --default && rvm cleanup all"

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER root

################################################################################
#
# Node.js
#
################################################################################


RUN curl -o- -L https://yarnpkg.com/install.sh > /usr/local/bin/yarn-installer.sh

ENV NVM_VERSION=0.35.3

# Install node.js
USER buildbot
RUN git clone https://github.com/creationix/nvm.git ~/.nvm && \
    cd ~/.nvm && \
    git checkout v$NVM_VERSION && \
    cd /

ENV ELM_VERSION=0.19.0-bugfix6
ENV YARN_VERSION=1.22.10

ENV NETLIFY_NODE_VERSION="12.18.0"

RUN /bin/bash -c ". ~/.nvm/nvm.sh && \
         nvm install --no-progress $NETLIFY_NODE_VERSION && \
         npm install -g sm grunt-cli bower elm@$ELM_VERSION && \
             bash /usr/local/bin/yarn-installer.sh --version $YARN_VERSION && \
         nvm alias default node && nvm cache clear"

USER root

################################################################################
#
# Python
#
################################################################################

ENV PIPENV_RUNTIME 2.7

USER buildbot

RUN virtualenv -p python2.7 --no-site-packages /opt/buildhome/python2.7 && \
    /bin/bash -c 'source /opt/buildhome/python2.7/bin/activate' && \
    ln -nfs /opt/buildhome/python2.7 /opt/buildhome/python2.7.11

RUN virtualenv -p python3.5 --no-site-packages /opt/buildhome/python3.5 && \
    /bin/bash -c 'source /opt/buildhome/python3.5/bin/activate' && \
    ln -nfs /opt/buildhome/python3.5 /opt/buildhome/python3.5.6

RUN virtualenv -p python3.7 --no-site-packages /opt/buildhome/python3.7 && \
    /bin/bash -c 'source /opt/buildhome/python3.7/bin/activate' && \
    ln -nfs /opt/buildhome/python3.7 /opt/buildhome/python3.7.2

RUN /opt/buildhome/python${PIPENV_RUNTIME}/bin/pip install "setuptools<45"
RUN /opt/buildhome/python${PIPENV_RUNTIME}/bin/pip install pipenv

USER root


################################################################################
#
# Binrc
#
################################################################################

ENV BINRC_VERSION 0.2.9

RUN mkdir /opt/binrc && cd /opt/binrc && \
    curl -sL https://github.com/netlify/binrc/releases/download/v${BINRC_VERSION}/binrc_${BINRC_VERSION}_Linux-64bit.tar.gz | tar zxvf - && \
    ln -s /opt/binrc/binrc_${BINRC_VERSION}_linux_amd64/binrc_${BINRC_VERSION}_linux_amd64 /usr/local/bin/binrc

# Create a place for binrc to link/persist installs to the PATH
USER buildbot
RUN mkdir -p /opt/buildhome/.binrc/bin
ENV PATH "/opt/buildhome/.binrc/bin:$PATH"

USER root

################################################################################
#
# Hugo
#
################################################################################

ENV HUGO_VERSION 0.54.0

RUN binrc install gohugoio/hugo ${HUGO_VERSION} -c /opt/buildhome/.binrc | xargs -n 1 -I{} ln -s {} /usr/local/bin/hugo_${HUGO_VERSION} && \
    ln -s /usr/local/bin/hugo_${HUGO_VERSION} /usr/local/bin/hugo

################################################################################
#
# Clojure
#
################################################################################

RUN mkdir /opt/leiningen && cd /opt/leiningen && \
    curl -sL https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein > lein && \
    chmod +x lein && \
    ln -s /opt/leiningen/lein /usr/local/bin/lein

RUN mkdir /opt/boot-clj && cd /opt/boot-clj && \
    curl -sL https://github.com/boot-clj/boot-bin/releases/download/2.5.2/boot.sh > boot && \
    chmod +x boot && \
    ln -s /opt/boot-clj/boot /usr/local/bin/boot

RUN curl -sL https://download.clojure.org/install/linux-install-1.10.1.492.sh | bash

USER buildbot

RUN lein

RUN boot -u

################################################################################
#
# PHP
#
################################################################################

USER root

COPY lib/dependencies /php/dependencies/
COPY lib/php/5.6 /php/5.6
COPY lib/php/7.2 /php/7.2
COPY lib/php/7.4 /php/7.4

RUN dpkg -i /php/dependencies/libssl1.1_1.1.1k-1+ubuntu16.04.1+deb.sury.org+0_amd64.deb
RUN dpkg -i /php/dependencies/psmisc_22.21-2.1ubuntu0.1_amd64.deb

RUN export DEBIAN_FRONTEND=noninteractive && \
    dpkg -i /php/dependencies/*.deb && \
    dpkg -i /php/5.6/*.deb && \
    dpkg -i /php/7.2/*.deb && \
    dpkg -i /php/7.4/*.deb

# set default to 5.6
RUN update-alternatives --set php /usr/bin/php5.6 && \
    update-alternatives --set phar /usr/bin/phar5.6 && \
    update-alternatives --set phar.phar /usr/bin/phar.phar5.6

RUN wget -nv https://raw.githubusercontent.com/composer/getcomposer.org/72bb6f65aa902c76c7ca35514f58cf79a293657d/web/installer -O - | php -- --quiet && \
    mv composer.phar /usr/local/bin/composer

USER buildbot

RUN mkdir -p /opt/buildhome/.php && ln -s /usr/bin/php5.6 /opt/buildhome/.php/php
ENV PATH "/opt/buildhome/.php:$PATH"

################################################################################
#
# Cask
#
################################################################################
USER buildbot
RUN rm -rf /opt/buildhome/.cask && git clone https://github.com/cask/cask.git /opt/buildhome/.cask
ENV PATH "$PATH:/opt/buildhome/.cask/bin"

###
# LZ4 Compression
###

USER root
ENV LZ4_VERSION 1.8.0
RUN curl -sL https://github.com/lz4/lz4/archive/v${LZ4_VERSION}.tar.gz | tar xzvf - && \
    cd lz4-${LZ4_VERSION} && \
    make && \
    make install && \
    cd .. && rm -rf lz4-${LZ4_VERSION}

################################################################################
#
# Go
#
################################################################################
USER buildbot
RUN mkdir -p /opt/buildhome/.gimme/bin/ && \
    mkdir -p /opt/buildhome/.gimme/env/ && \
    curl -sL -o /opt/buildhome/.gimme/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme && \
    chmod u+x /opt/buildhome/.gimme/bin/gimme
ENV PATH "$PATH:/opt/buildhome/.gimme/bin"
ENV GOPATH "/opt/buildhome/.gimme_cache/gopath"
ENV GOCACHE "/opt/buildhome/.gimme_cache/gocache"
# Install the default version
ENV GIMME_GO_VERSION "1.14.4"
ENV GIMME_ENV_PREFIX "/opt/buildhome/.gimme/env"
RUN gimme | bash

################################################################################
#
# Dotnet Core
#
################################################################################
WORKDIR /tmp
RUN wget https://dot.net/v1/dotnet-install.sh
RUN chmod u+x /tmp/dotnet-install.sh
RUN /tmp/dotnet-install.sh -c Current
ENV PATH "$PATH:/opt/buildhome/.dotnet/tools"
ENV PATH "$PATH:/opt/buildhome/.dotnet"
ENV DOTNET_ROOT "/opt/buildhome/.dotnet"
#populate local package cache
RUN dotnet new

################################################################################
#
# Swift
#
################################################################################
USER buildbot
ENV SWIFTENV_ROOT "/opt/buildhome/.swiftenv"
RUN git clone --depth 1 https://github.com/kylef/swiftenv.git "$SWIFTENV_ROOT"
ENV PATH "$SWIFTENV_ROOT/bin:$SWIFTENV_ROOT/shims:$PATH"

################################################################################
#
# Homebrew
#
################################################################################
USER root
RUN mkdir -p /home/linuxbrew/.linuxbrew && chown -R buildbot /home/linuxbrew/
USER buildbot
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew"
ENV PATH "${HOMEBREW_PREFIX}/bin:${PATH}"
ENV HOMEBREW_CELLAR "${HOMEBREW_PREFIX}/Cellar"
ENV HOMEBREW_REPOSITORY "${HOMEBREW_PREFIX}/Homebrew"
ENV HOMEBREW_CACHE "/opt/buildhome/.homebrew-cache"
RUN brew tap homebrew/bundle

WORKDIR /

################################################################################
#
# rustup
#
################################################################################
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
ENV PATH "$PATH:/opt/buildhome/.cargo/bin"

# Cleanup
USER root

# Add buildscript for local testing
RUN mkdir -p /opt/build-bin
ADD run-build-functions.sh /opt/build-bin/run-build-functions.sh
ADD run-build.sh /opt/build-bin/build
ADD buildbot-git-config /root/.gitconfig
RUN rm -r /tmp/*
RUN rm -r /php

USER buildbot
ARG NF_IMAGE_VERSION
ENV NF_IMAGE_VERSION ${NF_IMAGE_VERSION:-latest}

ARG NF_IMAGE_TAG
ENV NF_IMAGE_TAG ${NF_IMAGE_TAG:-latest}
