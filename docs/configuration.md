# Configuration

Configure JamServe before starting it. Paths below are relative to the server directory (`jamserve/` in a source checkout, or the extracted server directory for a release package).

## First-start configuration

1. Copy the first-start template to `data/config/firststart.config.json`, creating the directory first. If you change `JAM_DATA_PATH`, put the file in its `config/` directory instead.
   - **Source checkout:** Use `jamserve/config/firststart.config.dist.json` relative to the repository root.
   - **Release package:** The server archive does not include the template. Obtain it from the source for the same release tag.
2. Edit the JSON file to set an admin username and password and the media folder paths. The template contains example `adminUser` and `roots` entries. Root scan strategies are `auto`, `artistalbum`, `compilation` and `audiobook`.

Admin and roots are initialized only when their respective database tables are empty. Media folders can also be managed through the frontend.

**Security:** The file stores the initial password in plain text. Protect it and change the password after login.

## Environment variables

Set environment variables directly or create `.env` in the server directory using this example:

```dotenv
JAM_DOMAIN=http://localhost:4040
JAM_HOST=127.0.0.1
JAM_PORT=4040
JAM_LOG_LEVEL=info
JAM_DATA_PATH=./data/
JAM_FRONTEND_PATH=../jamberry/dist/
JAM_JWT_SECRET=<64-or-more-random-characters>
JAM_SESSION_SECRET=<different-64-or-more-random-characters>
JAM_JWT_MAXAGE="1 day"
JAM_SESSION_MAXAGE="1 day"
JAM_ALLOWED_COOKIE_DOMAINS=http://localhost:4040,http://localhost:4200
# Only disable secure cookies for local HTTP development.
JAM_SESSION_COOKIE_SECURE=false
JAM_SESSION_TRUST_PROXY=false
JAM_DB_DIALECT=sqlite
```

- Generate two different random secrets with `openssl rand -hex 32`; each must be at least 64 characters long.
- Set `JAM_FRONTEND_PATH` to the built JamBerry directory: `../jamberry/dist/` for a source checkout or `../jamberry` for the sibling release-package layout.
- For deployment, use HTTPS and configure the public URL and cookie origins accordingly. Only disable secure cookies for local HTTP development.

## Database

The example uses SQLite for development. Use PostgreSQL for multi-user deployments:

```dotenv
JAM_DB_DIALECT=postgres
JAM_DB_NAME=jam
JAM_DB_USER=jam
JAM_DB_PASSWORD=<database-password>
JAM_DB_HOST=127.0.0.1
JAM_DB_PORT=5432
# Alternatively, use the directory containing the PostgreSQL socket:
# JAM_DB_SOCKET=/var/run/postgresql/
```

## Other settings

- `JAM_DOMAIN` is the public server URL; `JAM_HOST` and `JAM_PORT` control the listening address.
- `JAM_ALLOWED_COOKIE_DOMAINS` is a comma-separated list of allowed origins. Secure session cookies default to enabled; set `JAM_SESSION_TRUST_PROXY=true` only when the first reverse proxy is trusted.
- `JAM_JWT_MAXAGE` and `JAM_SESSION_MAXAGE` accept durations such as `1 day`. An absent or invalid value falls back to one year for JWTs and no expiration for sessions; `0` also uses these defaults. `JAM_MIN_PASSWORD_LENGTH` defaults to 10.
- `JAM_LYRICS_WRITE_SIDECAR=false` disables writing fetched lyrics alongside media files. Existing sidecars are not overwritten.
- Optional service credentials include `JAM_ACOUSTID_API_KEY`, `JAM_LASTFM_API_KEY`, `JAM_DISCOGS_API_TOKEN`, `JAM_LRCLIB_API_KEY` and `JAM_LRCLIB_APP_ID`.
