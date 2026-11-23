# Docker deployment

The `ffalt/jam` image contains JamServe and JamBerry and is published for `amd64` and `arm64`
on [Docker Hub](https://hub.docker.com/r/ffalt/jam/tags). The deployment package runs that
image together with PostgreSQL through Docker Compose.

## Download

Download `jam-docker.zip` from the [latest release](https://github.com/ffalt/jam/releases/latest)
and extract it. The archive contains a `jam` directory with the compose file, the configuration
templates and the storage folders:

```shell
curl -LO https://github.com/ffalt/jam/releases/latest/download/jam-docker.zip
unzip jam-docker.zip
cd jam
```

Copy the default configuration files (DO NOT SKIP THIS STEP):

```shell
cp .env.dist .env
cp storage/data/config/firststart.config.json.dist storage/data/config/firststart.config.json
```

## Folder structure

```
jam
├── .env                      # JamServe settings
├── docker-compose.yml
└── storage                   # runtime data folder
    ├── data                    # where Jam stores its data
    │   ├── config                     # where Jam reads its configuration
    │   │   └── firststart.config.json # default admin user and media source settings
    │   └ ...                          # other cache directories
    ├── db                      # where the database stores its files
    ├── logs                    # where Jam stores its log files
    └── media                   # where you can store or link your media sources
```

Most of the configuration already matches the compose setup. The settings below have to be
changed by you.

## `.env`

Basic environment settings, read on startup; changes require a restart of the containers. See
the [configuration guide](configuration.md) for the full list of environment variables.

```dotenv
# Server domain URL (e.g. https://music.yourdomain.somewhere)
JAM_DOMAIN=http://localhost:4040

# Host address and port the container is exposed on (host-side binding only,
# the container itself always listens on 0.0.0.0:4040)
JAM_HOST=0.0.0.0
JAM_PORT=4040

# Log level, possible values: 'error' | 'warn' | 'info' | 'debug'
JAM_LOG_LEVEL=info

# Minimum password length
JAM_MIN_PASSWORD_LENGTH=10

# Due to CORS security you MUST name all domains where login with session cookie is allowed
# https://en.wikipedia.org/wiki/Cross-origin_resource_sharing
#  (background: random sites cannot access/create cookies for your domain)
JAM_ALLOWED_COOKIE_DOMAINS=http://localhost:4040

# REQUIRED - unique random strings to sign tokens and session cookies.
# Jam refuses to start unless each is at least 64 characters. Generate one for each with:
#   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
JAM_JWT_SECRET=
# Max age for a valid JWT token (e.g. '1 day', '1 month', '1 year', or 0 for no expiration)
JAM_JWT_MAXAGE="1 month"
JAM_SESSION_SECRET=
# Max age for a valid session cookie (same format as JAM_JWT_MAXAGE)
JAM_SESSION_MAXAGE="1 month"

# If true, session cookies are only available for https, NOT http
JAM_SESSION_COOKIE_SECURE=false

# Set true if you want to use a reverse proxy like nginx
JAM_SESSION_TRUST_PROXY=false

# Database name, user name and password
JAM_DB_NAME=jam
JAM_DB_USER=jam
JAM_DB_PASSWORD=jam

# Third-party API keys (optional)
# AcoustID API key for audio fingerprinting (https://acoustid.org/)
JAM_ACOUSTID_API_KEY=
# Discogs personal token for music metadata (https://www.discogs.com/)
JAM_DISCOGS_API_TOKEN=
# Last.fm API key for music metadata (https://www.last.fm/api)
JAM_LASTFM_API_KEY=
# LRCLib credentials for lyrics (https://lrclib.net/)
JAM_LRCLIB_APP_ID=
JAM_LRCLIB_API_KEY=

# Enable worker threads for audio processing tasks
# JAM_USE_TASKS=true
```

## `storage/data/config/firststart.config.json`

Media and user settings, applied only once on first start.

In Docker, all media paths are the container paths: replace
`<location on your system>/jam/storage/media/` with `/usr/share/media/`.

For example `/home/user/jam/storage/media/music/Awesome Collection` is entered as
`/usr/share/media/music/Awesome Collection`.

These settings are copied to the database on the first run; afterwards they can be changed in
the admin section of the frontend.

```json5
/*
  Add admin user and media folders on first start
 */
{
  /*
    Default admin user
  */
  "adminUser": {
    "name": "admin",
    /*
      Since the default admin password is stored in clear in this file,
      you MUST change it on first login
    */
    "pass": "your admin password"
  },
  /*
    Default media folders
    Scan strategies:
    'auto' -- try to figure it out
    'artistalbum' -- artist/album folder structure
    'compilation' -- bunch of compilation folders
    'audiobook' -- bunch of audiobook folders
   */
  "roots": [
    {"name": "Music", "path": "/usr/share/media/music", "strategy": "auto"},
    {"name": "Compilations", "path": "/usr/share/media/compilations", "strategy": "compilation"},
    {"name": "Soundtracks", "path": "path/to/soundtracks", "strategy": "compilation"},
    {"name": "Audiobooks", "path": "path/to/audiobooks", "strategy": "audiobook"}
  ]
}
```

## Run

Run these commands in the extracted `jam` directory.

Start:

```shell
docker compose up -d
```

Stop:

```shell
docker compose stop
```

Logs:

```shell
docker compose logs -f jam
```

Update to the current image:

```shell
docker compose pull
docker compose up -d
```

The compose file uses `ffalt/jam:latest`, so `docker compose pull` fetches the newest release.
To stay on a fixed version, set the image to `ffalt/jam:vX.Y.Z` in `docker-compose.yml`.

## Production checklist

When deploying with a real domain and HTTPS, update these settings in `.env`:

- `JAM_DOMAIN` - your public URL (e.g. `https://music.example.com`)
- `JAM_ALLOWED_COOKIE_DOMAINS` - same public URL
- `JAM_SESSION_COOKIE_SECURE=true` - required for HTTPS
- `JAM_SESSION_TRUST_PROXY=true` - required when behind a reverse proxy (e.g. nginx)
- `JAM_JWT_SECRET` and `JAM_SESSION_SECRET` - required in every deployment, not just in
  production; `.env.dist` ships them empty and Jam will not start until you generate them
