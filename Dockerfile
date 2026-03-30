ARG BASE_IMAGE=node:22-bookworm-slim
FROM ${BASE_IMAGE} as base

ARG APT_PACKAGES="apt-get update && apt-get install -y bash curl git build-essential"
ARG PREBUILD_COMMANDS="yarn install"
ARG POSTBUILD_COMMANDS="NODE_OPTIONS='--max-old-space-size=4096' yarn build"
ARG ROOT_DIRECTORY=.
ENV DEPLOY_CMD="env NODE_ENV=production node --icu-data-dir=node_modules/full-icu server/index.js"

WORKDIR /app

# Copy application code from the specified root directory
COPY ${ROOT_DIRECTORY} /app/

# Pre-build commands
RUN if [ -n "$PREBUILD_COMMANDS" ]; then \
echo "Running prebuild commands: $PREBUILD_COMMANDS"; \
sh -lc "$PREBUILD_COMMANDS"; \
fi

# Post-build commands
RUN if [ -n "$POSTBUILD_COMMANDS" ]; then \
echo "Running postbuild commands: $POSTBUILD_COMMANDS"; \
sh -lc "$POSTBUILD_COMMANDS"; \
fi

# Runtime command
CMD ["/bin/sh", "-c", "$DEPLOY_CMD"]
