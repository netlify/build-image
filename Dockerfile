FROM ubuntu:16.04

MAINTAINER Netlify

################################################################################
#
# Dependencies
#
################################################################################

ENV LANGUAGE en_US:en
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PANDOC_VERSION 2.2.1

# language export needed for ondrej/php PPA https://github.com/oerdnj/deb.sury.org/issues/56
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y update && \
    apt-get install -y --no-install-recommends software-properties-common language-pack-en-base apt-transport-https gnupg-curl && \
    echo 'Acquire::Languages {"none";};' > /etc/apt/apt.conf.d/60language && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
    locale-gen en_US.UTF-8 && \
    update-locale en_US.UTF-8 && \
    apt-key adv --fetch-keys https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc && \
    apt-key adv --fetch-keys https://packagecloud.io/github/git-lfs/gpgkey && \
    apt-add-repository -y -s 'deb https://packagecloud.io/github/git-lfs/ubuntu/ trusty main' && \
    add-apt-repository -y ppa:ondrej/php && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    add-apt-repository -y ppa:git-core/ppa && \
    add-apt-repository -y ppa:rwky/graphicsmagick && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    add-apt-repository -y ppa:kelleyk/emacs && \
    apt-add-repository -y 'deb https://packages.erlang-solutions.com/ubuntu trusty contrib' && \
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
        elixir \
        emacs25-nox \
        esl-erlang \
        expect \
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
        imagemagick \
        jpegoptim \
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
        libexif-dev \
        libffi-dev \
        libfontconfig1 \
        libgconf-2-4 \
        libgd-dev \
        libgdbm-dev \
        libgif-dev \
        libglib2.0-dev \
        libgmp3-dev \
        libgraphicsmagick-q16-3 \
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
        php5.6 \
        php5.6-xml \
        php5.6-mbstring \
        php5.6-gd \
        php5.6-sqlite3 \
        php5.6-curl \
        php5.6-zip \
        php7.2 \
        php7.2-xml \
        php7.2-mbstring \
        php7.2-gd \
        php7.2-sqlite3 \
        php7.2-curl \
        php7.2-zip \
        pngcrush \
        python-setuptools \
        python2.7-dev \
        python3 \
        python3-dev \
        python3.5 \
        python3.5-dev \
        python3.6 \
        python3.6-dev \
        rsync \
        software-properties-common \
        sqlite3 \
        ssh \
        strace \
        swig \
        tree \
        unzip \
        wget \
        xvfb \
        zip \
        && \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get autoremove -y && \
    unset DEBIAN_FRONTEND

# install jq 1.5 (Ubuntu 14.04 only provides 1.3)
RUN curl -sSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod +x /usr/local/bin/jq && \
    jq --version

RUN wget -nv https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && \
    tar -xf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && \
    cd wkhtmltox && \
    cp -r ./ /usr/ && \
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

USER buildbot
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys D39DC0E3 && \
    curl -sL https://get.rvm.io | bash -s stable --with-gems="bundler" --autolibs=read-fail

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /bin/bash -c "source ~/.rvm/scripts/rvm && \
                  rvm install 2.2.9 && rvm use 2.2.9 && gem install bundler && \
                  rvm install 2.3.6 && rvm use 2.3.6 && gem install bundler && \
                  rvm install 2.4.3 && rvm use 2.4.3 && gem install bundler && \
                  rvm use 2.3.6 --default && rvm cleanup all"

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER root

################################################################################
#
# Node.js
#
################################################################################


RUN curl -o- -L https://yarnpkg.com/install.sh > /usr/local/bin/yarn-installer.sh

# Install node.js
USER buildbot
RUN git clone https://github.com/creationix/nvm.git ~/.nvm && \
    cd ~/.nvm && \
    git checkout v0.33.4 && \
    cd /

ENV ELM_VERSION=0.17.1
ENV YARN_VERSION=1.3.2

RUN /bin/bash -c ". ~/.nvm/nvm.sh && \
         nvm install 4 && nvm use 4 && npm install -g sm grunt-cli bower elm@$ELM_VERSION && \
             bash /usr/local/bin/yarn-installer.sh --version $YARN_VERSION && \
         nvm install 6 && nvm use 6 && npm install -g sm grunt-cli bower elm@$ELM_VERSION && \
             bash /usr/local/bin/yarn-installer.sh --version $YARN_VERSION && \
         nvm install 8 && nvm use 8 && npm install -g sm grunt-cli bower elm@$ELM_VERSION && \
             bash /usr/local/bin/yarn-installer.sh --version $YARN_VERSION && \
         nvm alias default node && nvm cache clear"

USER root

################################################################################
#
# Python
#
################################################################################

ENV PIPENV_RUNTIME 2.7

RUN easy_install virtualenv==16.0.0

USER buildbot

RUN virtualenv -p python2.7 --no-site-packages /opt/buildhome/python2.7 && \
    /bin/bash -c 'source /opt/buildhome/python2.7/bin/activate' && \
    ln -nfs /opt/buildhome/python2.7 /opt/buildhome/python2.7.5

RUN virtualenv -p python3.4 --no-site-packages /opt/buildhome/python3.4 && \
    /bin/bash -c 'source /opt/buildhome/python3.4/bin/activate' && \
    ln -nfs /opt/buildhome/python3.4 /opt/buildhome/python3.4.0

RUN virtualenv -p python3.5 --no-site-packages /opt/buildhome/python3.5 && \
    /bin/bash -c 'source /opt/buildhome/python3.5/bin/activate' && \
    ln -nfs /opt/buildhome/python3.5 /opt/buildhome/python3.5.5

RUN virtualenv -p python3.6 --no-site-packages /opt/buildhome/python3.6 && \
    /bin/bash -c 'source /opt/buildhome/python3.6/bin/activate' && \
    ln -nfs /opt/buildhome/python3.6 /opt/buildhome/python3.6.4

RUN /opt/buildhome/python${PIPENV_RUNTIME}/bin/pip install pipenv

USER root


################################################################################
#
# Hugo
#
################################################################################

ENV BINRC_VERSION 0.2.5

RUN mkdir /opt/binrc && cd /opt/binrc && \
    curl -sL https://github.com/netlify/binrc/releases/download/v${BINRC_VERSION}/binrc_${BINRC_VERSION}_Linux-64bit.tar.gz | tar zxvf - && \
    ln -s /opt/binrc/binrc_${BINRC_VERSION}_linux_amd64/binrc_${BINRC_VERSION}_linux_amd64 /usr/local/bin/binrc

RUN binrc install spf13/hugo 0.17 -c /opt/buildhome/.binrc | xargs -n 1 -I{} ln -s {} /usr/local/bin/hugo_0.17 && \
    binrc install spf13/hugo 0.18 -c /opt/buildhome/.binrc | xargs -n 1 -I{} ln -s {} /usr/local/bin/hugo_0.18 && \
    binrc install spf13/hugo 0.19 -c /opt/buildhome/.binrc | xargs -n 1 -I{} ln -s {} /usr/local/bin/hugo_0.19 && \
    binrc install spf13/hugo 0.20 -c /opt/buildhome/.binrc | xargs -n 1 -I{} ln -s {} /usr/local/bin/hugo_0.20 && \
    ln -s /usr/local/bin/hugo_0.17 /usr/local/bin/hugo

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

USER buildbot

RUN lein

RUN boot -u

################################################################################
#
# PHP
#
################################################################################

USER root

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
ENV GIMME_GO_VERSION "1.10"
ENV GIMME_ENV_PREFIX "/opt/buildhome/.gimme/env"
RUN gimme

# Cleanup
USER root

# Add buildscript for local testing
ADD run-build-functions.sh /usr/local/bin/run-build-functions.sh
ADD run-build.sh /usr/local/bin/build
ADD buildbot-git-config /root/.gitconfig

USER buildbot
ARG NF_IMAGE_VERSION
ENV NF_IMAGE_VERSION ${NF_IMAGE_VERSION:-latest}
