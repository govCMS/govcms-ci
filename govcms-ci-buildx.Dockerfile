ARG DOCKER_VERSION="20.10.10"
ARG BUILDKIT_VERSION="0.9.1"
ARG BUILDX_VERSION="0.6.3"
ARG COMPOSE_VERSION="2.0.1"

FROM moby/buildkit:v${BUILDKIT_VERSION} as buildkit
FROM docker/buildx-bin:${BUILDX_VERSION} as buildx

FROM alpine:3.14 AS base

LABEL maintainer="govcms@finance.gov.au"
LABEL description="GovCMS base image for use in CI processes"

FROM base AS docker-static
ARG TARGETPLATFORM
ARG DOCKER_VERSION
WORKDIR /opt/docker
RUN DOCKER_ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
    "linux/amd64")   echo "x86_64"  ;; \
    "linux/arm/v7")  echo "armhf"   ;; \
    "linux/arm64")   echo "aarch64" ;; \
    *)               echo ""        ;; esac) \
  && echo "DOCKER_ARCH=$DOCKER_ARCH" \
  && wget -qO- "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz" | tar xvz --strip 1

FROM base AS compose
ARG TARGETPLATFORM
ARG COMPOSE_VERSION
WORKDIR /opt
RUN COMPOSE_ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
    "linux/amd64")   echo "linux-x86_64"  ;; \
    "linux/arm/v7")  echo "linux-armv7"  ;; \
    "linux/arm64")   echo "linux-aarch64"  ;; \
    *)               echo ""        ;; esac) \
  && echo "COMPOSE_ARCH=$COMPOSE_ARCH" \
  && wget -q "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-${COMPOSE_ARCH}" -qO "/opt/docker-compose" \
  && chmod +x /opt/docker-compose

FROM amazeeio/php:7.4-cli-drupal

RUN apk --update --no-cache add \
    bash \
    ca-certificates \
    docker-compose \
    openssh-client \
  && rm -rf /tmp/* /var/cache/apk/*

COPY --from=docker-static /opt/docker/ /usr/local/bin/
COPY --from=buildkit /usr/bin/buildctl /usr/local/bin/buildctl
COPY --from=buildkit /usr/bin/buildkit* /usr/local/bin/
COPY --from=buildx /buildx /usr/libexec/docker/cli-plugins/docker-buildx
COPY --from=compose /opt/docker-compose /usr/libexec/docker/cli-plugins/docker-compose

# https://github.com/docker-library/docker/pull/166
#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   docker-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
ENV DOCKER_CLI_EXPERIMENTAL=enabled

RUN docker --version \
  && buildkitd --version \
  && buildctl --version \
  && docker buildx version \
  && docker compose version \
  && docker-compose --version \
  && mkdir /certs /certs/client \
  && chmod 1777 /certs /certs/client

### OLD
RUN apk update \
  && apk add --no-cache \
      zip \
      zlib \
      libgcc \
  && apk add --no-cache -t .deps ca-certificates \
  && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
  && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk \
  && apk add glibc-2.29-r0.apk \
  && rm -rf /var/cache/apk/* \
  && apk del --purge .deps \
  && composer clear-cache \
  && rm -rf /app

# Install shellcheck.
RUN curl -L -o "/tmp/shellcheck-v0.7.1.tar.xz" "https://github.com/koalaman/shellcheck/releases/download/v0.7.1/shellcheck-v0.7.1.linux.x86_64.tar.xz" \
  && tar -C /tmp --xz -xvf "/tmp/shellcheck-v0.7.1.tar.xz" \
  && mv "/tmp/shellcheck-v0.7.1/shellcheck" /usr/bin/ \
  && chmod +x /usr/bin/shellcheck

# Install BATS.
RUN apk add --no-cache bats=1.3.0-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.14/main

# Required for docker-compose to find zlib.
ENV LD_LIBRARY_PATH=/lib:/usr/lib

# Install yq for YAML parsing.
RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64" \
  && chmod +x /usr/local/bin/yq

# Install jq for JSON parsing.
RUN wget -O /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" \
  && chmod +x /usr/local/bin/jq

# Install Ahoy.
RUN wget -O /usr/local/bin/ahoy "https://github.com/ahoy-cli/ahoy/releases/download/2.0.0/ahoy-bin-linux-amd64" \
  && chmod +x /usr/local/bin/ahoy

# Install Goss (and dgoss) for server validation.
ENV GOSS_FILES_STRATEGY=cp
RUN wget -O /usr/local/bin/goss https://github.com/aelsabbahy/goss/releases/download/v0.3.6/goss-linux-amd64 \
  && chmod +x /usr/local/bin/goss \
  && wget -O /usr/local/bin/dgoss https://raw.githubusercontent.com/aelsabbahy/goss/master/extras/dgoss/dgoss \
  && chmod +x /usr/local/bin/dgoss

# Install a stub for pygmy.
# Some frameworks may require presence of pygmy to run, but pygmy is not required in CI container.
RUN touch /usr/local/bin/pygmy \
  && chmod +x /usr/local/bin/pygmy

RUN git --version \
  && ssh -V \
  && zip --version \
  && unzip -v \
  && curl --version \
  && jq --version \
  && yq --version \
  && ahoy --version \
  && goss --version \
  && shellcheck --version \
  && bats -v \
  && docker --version \
  && docker-compose version \
  && docker compose version \
  && buildkitd --version \
  && buildctl --version \
  && docker buildx version \
  && composer --version \
  && npm -v \
  && node -v

RUN docker buildx create --name govcms-amd-arm --platform linux/amd64,linux/arm64

RUN docker buildx ls

COPY composer.json /govcms/
ENV COMPOSER_MEMORY_LIMIT=-1
RUN composer self-update --1 && composer install -d /govcms && composer cc
ENV PATH="/govcms/vendor/bin:${PATH}"
