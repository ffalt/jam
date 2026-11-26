# Jam Docker deployment

Runs [Jam](https://github.com/ffalt/jam) and PostgreSQL with Docker Compose.

## Quick start

```shell
cp .env.dist .env
cp storage/data/config/firststart.config.json.dist storage/data/config/firststart.config.json
docker compose up -d
```

`.env` needs a `JAM_JWT_SECRET` and a `JAM_SESSION_SECRET` of at least 64 characters each,
otherwise Jam refuses to start. Generate them with:

```shell
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Media folders are mounted from `storage/media` and are addressed as `/usr/share/media/...`
inside `storage/data/config/firststart.config.json`.

The stack runs PostgreSQL 19 and keeps its data in `storage/db/postgres19`. Updating to a
new PostgreSQL major version is not a plain `docker compose pull`: the data has to be
exported and imported again, see
[docs/postgres-upgrade.md](https://github.com/ffalt/jam/blob/main/docs/postgres-upgrade.md).

The full deployment guide, including all environment variables and the production checklist,
is at [docs/docker.md](https://github.com/ffalt/jam/blob/main/docs/docker.md).
