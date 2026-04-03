# ----------- BUILD STAGE -----------
FROM node:22-alpine AS builder

WORKDIR /app

# Copy only dependency files first (for caching)
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy rest of the code
COPY . .

# Build app
RUN NODE_OPTIONS="--max-old-space-size=4096" yarn build


# ----------- RUNTIME STAGE -----------
FROM node:22-alpine AS runtime

WORKDIR /app

# Copy only required artifacts from builder
COPY --from=builder /app ./

# Optional: reduce size further
RUN rm -rf node_modules/.cache

ENV NODE_ENV=production

CMD ["node", "--icu-data-dir=node_modules/full-icu", "server/index.js"]
