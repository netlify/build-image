FROM --platform=$BUILDPLATFORM ubuntu:20.04 as build-image

RUN apt-get -y update && \
    apt-get install -y \
      build-essential \
      procps \
      curl \
      file \
      git

################################################################################
#
# User
#
################################################################################

RUN adduser --system --disabled-password --uid 2500 --group --quiet buildbot --home /opt/buildhome

USER buildbot

USER root

RUN mkdir -p /home/linuxbrew/.linuxbrew && chown -R buildbot /home/linuxbrew/

USER buildbot
RUN if [ "$TARGETARCH" = "amd64" ] ; then /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; fi

ENV HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew"
ENV PATH "${HOMEBREW_PREFIX}/bin:${PATH}"
ENV HOMEBREW_CELLAR "${HOMEBREW_PREFIX}/Cellar"
ENV HOMEBREW_REPOSITORY "${HOMEBREW_PREFIX}/Homebrew"
ENV HOMEBREW_CACHE "/opt/buildhome/.homebrew-cache"

RUN if [ "$TARGETARCH" = "amd64" ] ; then brew tap homebrew/bundle; fi
