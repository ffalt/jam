# Installation

Install the [prerequisites](prerequisites.md) before following either installation method. To run Jam in containers instead, see the [Docker guide](docker.md); it needs no prerequisites besides Docker.

## From release packages

Download `jamserve-release.zip` and `jamberry-release.zip` from the same [GitHub release](https://github.com/ffalt/jam/releases). The release also provides SHA-256 files for verifying the downloads. Extract the archives into separate sibling directories; each archive contains the directory contents directly:

```shell
mkdir -p release/jamserve release/jamberry
unzip /path/to/jamserve-release.zip -d release/jamserve
unzip /path/to/jamberry-release.zip -d release/jamberry
cd release/jamserve
npm ci --omit=dev
```

Configure the server before starting it:

1. Follow the [configuration guide](configuration.md). Obtain the first-start template from the source for the same release tag, and use `../jamberry` as the frontend path for the sibling layout above.
2. Run `npm start` from the extracted server directory and open `http://localhost:4040/`. JamServe serves the extracted JamBerry files; there is no separate client process.

## From source

From the repository root, install and build both projects:

```shell
npm run install:all
npm run build
```

Configure the server before starting it:

1. Follow the [configuration guide](configuration.md), using `jamserve/config/firststart.config.dist.json` as the first-start template and `../jamberry/dist/` as the frontend path.
2. Run `npm start` in `jamserve/` and open `http://localhost:4040/`.
