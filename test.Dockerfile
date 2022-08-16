FROM ubuntu:20.04 as build-image

ARG TARGETARCH

RUN apt-get -y update && apt-get -y install wget

ENV PANDOC_VERSION 2.19
RUN wget --quiet https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-$TARGETARCH.deb



# ENV TARGETARCH "${TARGETARCH}"
# # The semver version associated with this build (i.e. v3.0.0)
# ARG NF_IMAGE_VERSION
# ENV NF_IMAGE_VERSION "${NF_IMAGE_VERSION:-latest}"
# # The commit SHA tag associated with this build
# ARG NF_IMAGE_TAG
# ENV NF_IMAGE_TAG "${NF_IMAGE_TAG:-latest}"
# # The codename associated with this build (i.e. focal)
# ARG NF_IMAGE_NAME
# ENV NF_IMAGE_NAME "${NF_IMAGE_NAME:-focal}"

# ENV LANGUAGE en_US:en
# ENV LANG en_US.UTF-8
# ENV LC_ALL en_US.UTF-8
# ENV PANDOC_VERSION 2.13

# LABEL maintainer Netlify

# ################################################################################
# #
# # Dependencies
# #
# ################################################################################

# # language export needed for ondrej/php PPA https://github.com/oerdnj/deb.sury.org/issues/56
# RUN export DEBIAN_FRONTEND=noninteractive && \
#     apt-get -y update && \
#     apt-get install -y --no-install-recommends software-properties-common language-pack-en-base apt-transport-https curl gnupg && \
#     echo 'Acquire::Languages {"none";};' > /etc/apt/apt.conf.d/60language && \
#     echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
#     echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
#     locale-gen en_US.UTF-8 && \
#     update-locale en_US.UTF-8 && \
#     # apt-key adv --fetch-keys https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc && \
#     add-apt-repository -y ppa:ondrej/php && \
#     # add-apt-repository -y ppa:openjdk-r/ppa && \
#     # add-apt-repository -y ppa:git-core/ppa && \
#     # add-apt-repository -y ppa:deadsnakes/ppa && \
#     # apt-add-repository -y 'deb https://packages.erlang-solutions.com/ubuntu focal contrib' && \
#     apt-get -y update && \
#     apt-get install -y --no-install-recommends \
#         advancecomp \
#         apache2-utils \
#         autoconf \
#         automake \
#         bison \
#         build-essential \
#         bzr \
#         cmake \
#         doxygen \
#         elixir \
#         emacs-nox \
#         expect \
#         file \
#         fontconfig \
#         fontconfig-config \
#         g++ \
#         gawk \
#         git \
#         git-lfs \
#         gifsicle \
#         gobject-introspection \
#         graphicsmagick \
#         graphviz \
#         gtk-doc-tools \
#         gnupg2 \
#         imagemagick \
#         iptables \
#         jpegoptim \
#         jq \
#         language-pack-ar \
#         language-pack-ca \
#         language-pack-cs \
#         language-pack-da \
#         language-pack-de \
#         language-pack-el \
#         language-pack-es \
#         language-pack-eu \
#         language-pack-fi \
#         language-pack-fr \
#         language-pack-gl \
#         language-pack-he \
#         language-pack-hi \
#         language-pack-it \
#         language-pack-ja \
#         language-pack-ka \
#         language-pack-ko \
#         language-pack-nn \
#         language-pack-pl \
#         language-pack-pt \
#         language-pack-ro \
#         language-pack-ru \
#         language-pack-sv \
#         language-pack-ta \
#         language-pack-th \
#         language-pack-tr \
#         language-pack-uk \
#         language-pack-vi \
#         language-pack-zh-hans \
#         language-pack-zh-hant \
#         libasound2 \
#         libcurl4 \
#         libcurl4-gnutls-dev \
#         libenchant1c2a \
#         libexif-dev \
#         libffi-dev \
#         libfontconfig1 \
#         libgbm1 \
#         libgconf-2-4 \
#         libgd-dev \
#         libgdbm-dev \
#         libgif-dev \
#         libglib2.0-dev \
#         libgmp3-dev \
#         libgsl23 \
#         libgsl-dev \
#         libgtk-3-0 \
#         libgtk2.0-0 \
#         libicu-dev \
#         libimage-exiftool-perl \
#         libjpeg-progs \
#         libjpeg-turbo8-dev \
#         libmagickwand-dev \
#         libmcrypt-dev \
#         libncurses5-dev \
#         libnss3 \
#         libpng-dev \
#         libreadline6-dev \
#         librsvg2-bin \
#         libsm6 \
#         libsqlite3-dev \
#         libssl-dev \
#         libtiff5-dev \
#         libtool \
#         libwebp-dev \
#         libwebp6 \
#         libxml2-dev \
#         libxrender1 \
#         libxslt-dev \
#         libxss1 \
#         libxtst6 \
#         libvips-dev \
#         libvips-tools \
#         libyaml-dev \
#         mercurial \
#         # musl and musl-tools are needed for certain rust dependencies (ring) to compile correctly
#         # see https://github.com/netlify/pillar-runtime/issues/401
#         musl \
#         musl-tools \
#         nasm \
#         openjdk-8-jdk \
#         optipng \
#         php7.4 \
#         php7.4-xml \
#         php7.4-mbstring \
#         php7.4-gd \
#         php7.4-sqlite3 \
#         php7.4-curl \
#         php7.4-zip \
#         php7.4-intl \
#         php8.0 \
#         php8.0-xml \
#         php8.0-mbstring \
#         php8.0-gd \
#         php8.0-sqlite3 \
#         php8.0-curl \
#         php8.0-zip \
#         php8.0-intl \
#         pngcrush \
#         # procps is needed for homebrew on linux arm
#         procps \
#         python-setuptools \
#         python3-setuptools \
#         python3.8-dev \
#         rlwrap \
#         rsync \
#         software-properties-common \
#         sqlite3 \
#         ssh \
#         strace \
#         swig \
#         tree \
#         unzip \
#         virtualenv \
#         wget \
#         xvfb \
#         zip \
#         # zstd is the compression algorithm for tar that is used by buildbot cache compression
#         zstd \
#         # needed for wkhtmltopdf
#         xfonts-base \
#         xfonts-75dpi \
#         # dotnet core dependencies
#         libunwind8-dev \
#         libicu-dev \
#         liblttng-ust0 \
#         libkrb5-3

# RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
#     dpkg -i erlang-solutions_2.0_all.deb && \
#     rm erlang-solutions_2.0_all.deb && \
#     # set the DEBIAN_FRONTEND to noninteractive to install erlang
#     DEBIAN_FRONTEND=noninteractive \
#     apt-get update && \
#     apt-get install -y esl-erlang

# RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
#     apt-get autoremove -y && \
#     unset DEBIAN_FRONTEND

# # RUN wget -nv --quiet https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_$TARGETARCH.deb && \
# #     dpkg -i wkhtmltox_0.12.6-1.focal_$TARGETARCH.deb

# ENV PANDOC_VERSION 2.19
#     # install Pandoc (more recent version to what is provided in Ubuntu 14.04)
# RUN wget --quiet https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-$TARGETARCH.deb
#     # dpkg -i pandoc-$PANDOC_VERSION-1-$TARGETARCH.deb
# #     rm pandoc-$PANDOC_VERSION-1-$TARGETARCH.deb && \
# #     pandoc -v
