# build context is the repo root: docker build -f docker/jam/Dockerfile .
ARG JAM_VERSION=dev

# build stages - the output (js, html, css) is platform independent, so they run on the build platform
# and the multi platform build does not need to emulate the angular & typescript compilers

# jamserve: dist, static & production package.json/package-lock.json in jamserve/deploy
FROM --platform=$BUILDPLATFORM node:26-trixie-slim AS serve-build
WORKDIR /src/jamserve
COPY jamserve/package.json jamserve/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --ignore-scripts
COPY jamserve/ ./
# deploy.ts runs `npm i` only to create the production package-lock.json, native modules are not needed here
RUN --mount=type=cache,target=/root/.npm npm_config_ignore_scripts=true npm run build:deploy

# jamberry: angular production build in jamberry/dist
FROM --platform=$BUILDPLATFORM node:26-trixie-slim AS berry-build
WORKDIR /src/jamberry
COPY jamberry/package.json jamberry/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY jamberry/ ./
RUN npm run build:deploy

FROM node:26-trixie-slim AS base

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates ffmpeg flac libchromaprint-tools mp3val \
    && apt-get autoremove -y \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/node/jam/logs /home/node/jam/data \
    && chown -R node:node /home/node/jam/logs /home/node/jam/data

# copy startup script
COPY docker/jam/static/start.sh /home/node/start.sh

ARG JAM_VERSION
ENV JAMSERVE_VERSION=${JAM_VERSION}
ENV JAMBERRY_VERSION=${JAM_VERSION}

# copy jamserve & jamberry from the build stages
COPY --from=serve-build /src/jamserve/deploy /home/node/jam/serve
COPY --from=berry-build /src/jamberry/dist /home/node/jam/berry

# copy jamserve default config
COPY docker/jam/static/.env /home/node/jam/serve/.env

ENV NODE_ENV=production
WORKDIR /home/node/jam/serve

# install app dependencies in a separate stage, so npm's cache stays out of the final image.
# the native modules (sqlite3, bcrypt) install prebuilt binaries; these need glibc 2.38, which is
# why the base image is trixie (2.41) and not bookworm (2.36).
FROM base AS builder
RUN npm ci --omit=dev

# final image - take only node_modules from the builder stage, leaving npm's cache behind
FROM base AS final
COPY --from=builder /home/node/jam/serve/node_modules ./node_modules

# change to user
USER node
# set home directory for user
ENV HOME=/home/node
EXPOSE 4040
CMD ["sh", "/home/node/start.sh"]
