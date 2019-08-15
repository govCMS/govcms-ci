FROM docker/compose:1.24.1 AS docker-compose
FROM docker:18.09 AS docker

FROM amazeeio/php:7.2-cli-drupal

RUN apk update \
  && apk add --no-cache \
      jq \
      zip \
      zlib \
      libgcc \
  && apk add --no-cache -t .deps ca-certificates \
  && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
  && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk \
  && apk add glibc-2.29-r0.apk \
  && apk add --no-cache bash git openssh py-pip \
  && pip install shyaml \
  && rm -rf /var/cache/apk/* \
  && apk del --purge .deps

# temporary package overrides to remediate secvuls
RUN apk del --no-cache curl libcurl && apk add --no-cache "curl=7.64.0-r2" "libcurl=7.64.0-r2" --repository http://dl-cdn.alpinelinux.org/alpine/v3.8/main/ \
  && apk del --no-cache expat && apk add --no-cache "expat=2.2.7-r0" "expat=2.2.7-r0" --repository http://dl-cdn.alpinelinux.org/alpine/v3.8/main/

# Required for docker-compose to find zlib.
ENV LD_LIBRARY_PATH=/lib:/usr/lib

COPY --from=docker /usr/local/bin/docker /bin
COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose

# Install Goss.
ENV GOSS_FILES_STRATEGY=cp
RUN curl -fsSL https://goss.rocks/install | sh

# Install Ahoy.
RUN curl -L https://github.com/ahoy-cli/ahoy/releases/download/2.0.0/ahoy-bin-`uname -s`-amd64 -o /usr/local/bin/ahoy \
  && chmod +x /usr/local/bin/ahoy

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
  && shyaml --version \
  && ahoy --version \
  && goss --version \
  && docker --version \
  && docker-compose version \
  && composer --version \
  && npm -v \
  && node -v

RUN composer clear-cache \
  && rm -rf /app
