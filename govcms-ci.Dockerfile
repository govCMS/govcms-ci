FROM uselagoon/php-8.1-cli-drupal:latest

LABEL maintainer="govcms@finance.gov.au"
LABEL description="GovCMS base image for use in CI processes"

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
COPY --from=koalaman/shellcheck-alpine:v0.8.0 /bin/shellcheck /usr/local/bin/shellcheck

# Install BATS.
COPY --from=bats/bats:1.6.0 /opt/bats /opt/bats
RUN ln -s /opt/bats/bin/bats /usr/local/bin/bats

# Required for docker-compose to find zlib.
ENV LD_LIBRARY_PATH=/lib:/usr/lib

COPY --from=docker:20.10.14 /usr/local/bin/docker /bin
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx
COPY --from=linuxserver/docker-compose:1.29.2-alpine /usr/local/bin/docker-compose /usr/local/bin/docker-compose

# Install yq for YAML parsing.
RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64" \
  && chmod +x /usr/local/bin/yq

# Install jq for JSON parsing.
RUN wget -O /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" \
  && chmod +x /usr/local/bin/jq

# Install Ahoy.
RUN arch=$(uname -m) && arch="${arch/aarch64/arm64}" && arch="${arch/x86_64/amd64}" \
  && wget -O /tmp/ahoy.tar.gz "https://github.com/ocean/ahoy/releases/download/2.1.0/ahoy_linux_${arch}.tar.gz" \
  && tar -xf /tmp/ahoy.tar.gz --directory /tmp && mv /tmp/ahoy /usr/local/bin/ahoy \
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

COPY --from=ghcr.io/salsadigitalauorg/shipshape:latest /usr/local/bin/shipshape /usr/local/bin/shipshape

RUN set -x \
  && git --version \
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
  && composer --version \
  && npm -v \
  && node -v \
  && shipshape --version

COPY composer.json /govcms/
ENV COMPOSER_MEMORY_LIMIT=-1
RUN composer self-update --1 && composer install -d /govcms && composer cc
ENV PATH="/govcms/vendor/bin:${PATH}"
