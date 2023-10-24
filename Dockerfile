FROM elixir:1.14-otp-25-slim as build

# Install deps
RUN set -xe; \
      apt-get update && \
      apt-get install -y \
        ca-certificates \
        build-essential  \
        git \
        libmcrypt-dev;

# Use the standard /usr/local/src destination
RUN mkdir -p /usr/local/src/warehouse

COPY . /usr/local/src/warehouse/

# ARG is available during the build and not in the final container
# https://vsupalov.com/docker-arg-vs-env/
ARG MIX_ENV=prod
ARG APP_NAME=warehouse

# Use `set -xe;` to enable debugging and exit on error
# More verbose but that is often beneficial for builds
RUN set -xe; \
    cd /usr/local/src/warehouse/; \
    mix local.hex --force; \
    mix local.rebar --force; \
    mix deps.get; \
    mix deps.compile --all; \
    mix release

FROM debian:11.6-slim as release

RUN set -xe; \
    apt-get update &&  \
    apt-get install -y  \
        ca-certificates \
        libmcrypt4 \
        openssl;

# Create a `warehouse` group & user
# I've been told before it's generally a good practice to reserve ids < 1000 for the system
RUN set -xe; \
    adduser --uid 1000 --system --home /warehouse --shell /bin/sh --group warehouse;

ARG APP_NAME=warehouse

# Copy the release artifact and set `warehouse` ownership
COPY --chown=warehouse:warehouse --from=build /usr/local/src/warehouse/_build/prod/rel/${APP_NAME} /warehouse

# These are fed in from the build script
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

# `Maintainer` has been deprecated in favor of Labels / Metadata
# https://docs.docker.com/engine/reference/builder/#maintainer-deprecated
LABEL \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.description="warehouse" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/system76/warehouse" \
    org.opencontainers.image.title="warehouse" \
    org.opencontainers.image.vendor="system76" \
    org.opencontainers.image.version="${VERSION}"

ENV \
    PATH="/usr/local/bin:$PATH" \
    VERSION="${VERSION}" \
    APP_REVISION="${VERSION}" \
    MIX_APP="warehouse" \
    MIX_ENV="prod" \
    SHELL="/bin/bash" \
    LANG="C.UTF-8"

# Drop down to our unprivileged `warehouse` user
USER warehouse

WORKDIR /warehouse

EXPOSE 50051

ENTRYPOINT ["/warehouse/bin/warehouse"]

CMD ["start"]
