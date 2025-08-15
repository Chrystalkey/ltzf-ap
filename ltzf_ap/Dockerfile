# Use the official Elixir image as the base image
FROM elixir:1.15-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git nodejs npm

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod

# Cache dependencies by copying mix files first
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy config files
COPY config/config.exs config/${MIX_ENV}.exs config/
COPY config/runtime.exs config/

# Copy assets
COPY priv priv
COPY assets assets

# Copy source code
COPY lib lib

# Build assets (always build to ensure they exist)
RUN mkdir -p priv/static/assets
RUN mix tailwind ltzf_ap --minify
RUN mix esbuild ltzf_ap --minify
RUN mix assets.deploy

# Compile the release
RUN mix do compile, release

# Ensure static files are included in the release
RUN mkdir -p _build/prod/rel/ltzf_ap/priv && cp -r priv/static _build/prod/rel/ltzf_ap/priv/

# Start a new build stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

# Create app user and group
RUN addgroup -g 1001 -S app && \
    adduser -S app -u 1001

# Set working directory
WORKDIR /app

# Copy release from builder stage
COPY --from=builder --chown=app:app /app/_build/prod/rel/ltzf_ap ./

# Change to the app user
USER app

# Set environment variables
ENV PHX_SERVER=true
ENV PORT=4000

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/ || exit 1

# Start the application
CMD ["bin/ltzf_ap", "start"] 