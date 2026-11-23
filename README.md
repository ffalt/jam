# Jam

Jam is my long-term pet project to manage, stream and edit my own music collection.
It keeps evolving along with my collection and ideas.

Your music, your server: Jam is a self-hosted Spotify alternative for the music you own, with no subscription fees, third-party tracking or calling home.
Optional features can still connect to external services for metadata, lyrics and podcasts.

This repository contains JamServe, the TypeScript/Node.js server, JamBerry, the Angular web client, their Docker image and the Docker Compose deployment stack.

## Features

- Scan and organize music, compilations and audiobooks from multiple media folders.
- Stream and transcode audio through the JamBerry web client, with playlists and playback queues.
- Edit MP3 ID3v2 and FLAC tags, match releases with MusicBrainz or Discogs, and identify recordings using audio fingerprints.
- Find and subscribe to podcasts and manage their episodes.
- Detect track health issues and repair supported MP3 problems.
- Enrich the library with metadata and lyrics from MusicBrainz, Discogs, Last.fm, Wikipedia, Lyrics.ovh, LRCLib and AcoustID.
- Manage users and access the library through REST and GraphQL APIs.
- Use PostgreSQL or SQLite for the library database.

See also [JamPacked](https://github.com/ffalt/jampacked) for the mobile app.

## Installation and usage

For Docker deployment, see the [Docker guide](docs/docker.md). The `ffalt/jam` image includes both JamServe and JamBerry and supports AMD64 and ARM64; the `jam-docker.zip` release asset contains the Docker Compose stack.

See the guides to [prerequisites](docs/prerequisites.md), [installation](docs/installation.md), [Docker deployment](docs/docker.md) and [configuration](docs/configuration.md).

## Development

The server and client are independent npm projects with separate lockfiles. From the repository root:

```shell
npm run install:all   # npm ci in jamserve/ and jamberry/
npm run build         # build both
npm test              # test both
npm run lint          # lint both
```

See the development guides for [JamServe](jamserve/README.md), [JamBerry](jamberry/README.md) and [Docker images](docker/README.md).

## Release

The repository shares one version across JamServe, JamBerry and the Docker image. Use conventional commits with a scope (`serve`, `berry` or `docker`), for example `fix(berry): ...`.

```shell
npm ci
npm run release
git push --follow-tags origin main
```

The release command updates package versions and the changelog and creates a `vX.Y.Z` tag. Pushing the tag runs `.github/workflows/release.yml`, which tests and publishes the release archives, the Docker Compose package, the `ffalt/jam` image and the `release` branch, which holds the built server and client in the same layout as the image.
