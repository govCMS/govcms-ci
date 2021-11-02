FROM debian:stable-slim

LABEL maintainer="govcms@finance.gov.au"
LABEL description="GovCMS base image for use in CI processes"

# TODO remove config.json this flag once it's not needed for `buildx` anymore
COPY buildx/config.json /root/.docker/
COPY buildx/debian-backports-pin-600.pref /etc/apt/preferences.d/
COPY buildx/debian-backports.list /etc/apt/sources.list.d/

# Upgrades the image, Installs docker and qemu
RUN  set -eux; \
    \
    export DEBIAN_FRONTEND=noninteractive; \
    export TERM=linux; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      gnupg2 \
      software-properties-common \
      \
      ca-certificates \
      \
      git \
      jq \
      curl \
      wget \
      \
      binfmt-support \
      qemu-user-static \
    ; \
    # Workaround for https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=923479
    c_rehash; \
    \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -; \
    add-apt-repository "deb https://download.docker.com/linux/debian $(lsb_release -cs) stable"; \
    apt-get update; \
    apt-get install -y  --no-install-recommends \
      docker-ce-cli \
      docker-compose \
    ; \
    apt-get autoremove --purge -y \
      apt-transport-https \
      gnupg2 \
      software-properties-common \
    ; \
    apt-get autoremove --purge -y; \
    rm -rf /var/lib/apt/lists/* /var/log/* /var/tmp/* /tmp/*; \
    \
    # Versions
    qemu-i386-static --version; \
    docker buildx version

##
## Adds common GovCMS tooling
##
RUN apt-get update
RUN apt-get install -y zip unzip ssh

ENV PATH="/govcms/vendor/bin:/usr/local/bin:${PATH}"

# Install yq (jq already installed)
RUN curl -L "https://github.com/mikefarah/yq/releases/download/v4.14.1/yq_$(uname -s)_$(uname -m)" -o /usr/local/bin/yq &&\
    chmod +x /usr/local/bin/yq

# Install ahoy
RUN curl -L "https://github.com/ahoy-cli/ahoy/releases/download/2.0.0/ahoy-bin-$(uname -s)-$(uname -m)" -o /usr/local/bin/ahoy &&\
    chmod +x /usr/local/bin/ahoy

# Install a stub for pygmy.
# Some frameworks may require presence of pygmy to run, but pygmy is not required in CI container.
RUN touch /usr/local/bin/pygmy \
  && chmod +x /usr/local/bin/pygmy

RUN git --version \
  && zip --version \
  && unzip -v \
  && curl --version \
  && jq --version \
  && yq --version \
  && goss --version \
  && shellcheck --version \
  && bats -v \
  && docker --version \
  && docker-compose version \
  && composer --version \
  && npm -v \
  && node -v

COPY composer.json /govcms/
ENV COMPOSER_MEMORY_LIMIT=-1
RUN composer self-update --1 && composer install -d /govcms && composer cc
