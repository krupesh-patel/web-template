# ----------- BUILD STAGE -----------
FROM node:22-bookworm-slim AS builder

WORKDIR /app

# -------- System dependencies (from APT_PACKAGES) --------
ARG APT_PACKAGES="None"
RUN if [ -n "$APT_PACKAGES" ] && [ "$APT_PACKAGES" != "None" ]; then \
apt-get update && apt-get install -y $APT_PACKAGES && rm -rf /var/lib/apt/lists/*; \
fi

# -------- Copy dependency files first (better caching) --------
COPY package.json yarn.lock ./

# -------- Prebuild (dependency install) --------
ARG PREBUILD_COMMANDS="yarn install"
RUN if [ -n "$PREBUILD_COMMANDS" ]; then \
echo "Running prebuild commands: $PREBUILD_COMMANDS"; \
sh -lc "$PREBUILD_COMMANDS"; \
fi

# -------- Copy full app --------
ARG ROOT_DIRECTORY=.
COPY ${ROOT_DIRECTORY} /app/

# -------- Postbuild (build step) --------
ARG POSTBUILD_COMMANDS="yarn run build"
RUN if [ -n "$POSTBUILD_COMMANDS" ]; then \
echo "Running postbuild commands: $POSTBUILD_COMMANDS"; \
sh -lc "$POSTBUILD_COMMANDS"; \
fi


# ----------- RUNTIME STAGE -----------
FROM node:22-bookworm-slim AS runtime

WORKDIR /app

# -------- Runtime system deps (keep minimal) --------
RUN apt-get update && apt-get install -y \
curl \
&& rm -rf /var/lib/apt/lists/*

# -------- Copy built app from builder --------
COPY --from=builder /app /app

# Optional cleanup
RUN rm -rf node_modules/.cache

# -------- Runtime ENV --------
ENV NODE_ENV=production
ENV DEPLOY_CMD="node --icu-data-dir=node_modules/full-icu server/index.js"

EXPOSE 3000

CMD ["/bin/sh", "-c", "$DEPLOY_CMD"]
