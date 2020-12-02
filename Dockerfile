FROM elixir:1.10-alpine as build

# Install deps
RUN set -xe; \
    apk add --update  --no-cache --virtual .build-deps \
        ca-certificates \
        g++ \
        gcc \
        git \
        make \
        musl-dev \
        tzdata;

# Use the standard /usr/local/src destination
RUN mkdir -p /usr/local/src/copy_cat

COPY . /usr/local/src/copy_cat/

# ARG is available during the build and not in the final container
# https://vsupalov.com/docker-arg-vs-env/
ARG MIX_ENV=prod
ARG APP_NAME=copy_cat

# Use `set -xe;` to enable debugging and exit on error
# More verbose but that is often beneficial for builds
RUN set -xe; \
    cd /usr/local/src/copy_cat/; \
    mix local.hex --force; \
    mix local.rebar --force; \
    mix deps.get; \
    mix deps.compile --all; \
    mix release

FROM alpine:3.9 as release

RUN set -xe; \
    apk add --update  --no-cache --virtual .runtime-deps \
        ca-certificates \
        libmcrypt \
        ncurses-libs \
        tzdata;

# Create a `copy_cat` group & user
# I've been told before it's generally a good practice to reserve ids < 1000 for the system
RUN set -xe; \
    addgroup -g 1000 -S copy_cat; \
    adduser -u 1000 -S -h /copy_cat -s /bin/sh -G copy_cat copy_cat;

ARG APP_NAME=copy_cat

# Copy the release artifact and set `copy_cat` ownership
COPY --chown=copy_cat:copy_cat --from=build /usr/local/src/copy_cat/_build/prod/rel/${APP_NAME} /copy_cat

# These are fed in from the build script
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

# `Maintainer` has been deprecated in favor of Labels / Metadata
# https://docs.docker.com/engine/reference/builder/#maintainer-deprecated
LABEL \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.description="copy_cat" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/system76/copy_cat" \
    org.opencontainers.image.title="copy_cat" \
    org.opencontainers.image.vendor="system76" \
    org.opencontainers.image.version="${VERSION}"

ENV \
    PATH="/usr/local/bin:$PATH" \
    VERSION="${VERSION}" \
    MIX_APP="copy_cat" \
    MIX_ENV="prod" \
    SHELL="/bin/bash"

# Drop down to our unprivileged `copy_cat` user
USER copy_cat

WORKDIR /copy_cat

EXPOSE 8080

ENTRYPOINT ["/copy_cat/bin/copy_cat"]

CMD ["start"]
