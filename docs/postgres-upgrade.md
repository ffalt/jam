# Upgrading PostgreSQL from 17 to 19

> [!IMPORTANT]
> This guide is for Jam installations that run in Docker Compose and have been set up previously with PostgreSQL 17. 
> If you are running Jam in a different environment, or if you are already on PostgreSQL 19, this guide does not apply.

The previous Jam's Docker Compose stack did run PostgreSQL 17. This guide moves an existing
installation to PostgreSQL 19 without losing data.

> Changing the image tag on its own is not enough. Each PostgreSQL major version
> stores its data in a different on-disk format, so PostgreSQL 19 refuses to start
> on a data directory written by 17. The data has to be exported and imported again.

Jam's database only holds metadata: users, media roots, playlists, play history and
the library index. Your music files are not in it and are never touched. The database
stays relatively small, so exporting and importing it takes a few minutes at most.

## Before you start

- **Export your data before you change anything.** The export needs the running
  PostgreSQL 17 container.
- Jam is offline from the moment you stop it until the import is finished.
- Make sure you have enough free disk space for the export file and for a second copy
  of the database in `storage/db/postgres19`.
- Run every command from your Jam folder, the one that contains `docker-compose.yml`
  and `.env`.
- Pin a released PostgreSQL 19 version, for example `postgres:19`. Never point a real
  installation at a `19beta` or `19rc` tag.

## Upgrade with the helper script

The stack ships with `scripts/postgres-upgrade.sh`, which runs the export and the
import for you and checks along the way that the right PostgreSQL version is running.

Both commands take the version you are leaving and the one you move to, so the same
script works for later upgrades such as 19 to 20. Called without versions it assumes
17 to 19.

### 1. Export your data

```shell
scripts/postgres-upgrade.sh dump 17
```

This stops Jam, exports the database to `jam-pg17.sql`, checks that the file actually
contains your data, and stops PostgreSQL. It refuses to run unless PostgreSQL 17 is the
version actually running, so you cannot export an empty database by mistake.

### 2. Switch to PostgreSQL 19

Edit the `postgres` service in `docker-compose.yml`:

```yaml
  postgres:
    image: postgres:19        # pin a released 19 version
    container_name: jam-postgres
    volumes:
      - type: bind
        source: ./storage/db/postgres19
        target: /var/lib/postgresql
    environment:
       POSTGRES_DB: "${JAM_DB_NAME}"
       POSTGRES_USER: "${JAM_DB_USER}"
       POSTGRES_PASSWORD: "${JAM_DB_PASSWORD}"
```

Two things change, and both matter:

1. **The image tag**, from `postgres:17.12` to a pinned `postgres:19`.
2. **The volume.** Since PostgreSQL 18 the official image keeps its data in
   `/var/lib/postgresql/<major>/docker` and expects the volume at
   `/var/lib/postgresql`, not at `/var/lib/postgresql/data` as before. Mounting the
   old path makes the container fail at startup. The host folder also changes to
   `storage/db/postgres19`, so your PostgreSQL 17 data stays untouched for a rollback.

Nothing else changes. The `jam` service, the ports and your `.env` settings stay as
they are.

### 3. Import your data and start Jam

```shell
scripts/postgres-upgrade.sh restore 17 19
```

This creates `storage/db/postgres19`, starts PostgreSQL 19, waits until it is ready,
imports `jam-pg17.sql`, refreshes the query planner statistics and starts Jam. If the
import reports a problem it stops before starting Jam and points you at
`jam-pg19-restore.log`.

Then follow the logs and check that Jam comes up:

```shell
docker compose logs -f jam
```

## Upgrade by hand

The same procedure without the script, if you prefer to see each step.

### 1. Export your data, still on PostgreSQL 17

```shell
docker compose stop jam
docker compose exec -T postgres sh -c 'pg_dumpall -U "$POSTGRES_USER"' > jam-pg17.sql
docker compose stop postgres
```

The command reads the user name from the container, so you do not need to load `.env`
into your shell first.

Check that the export is not empty before you go on:

```shell
grep -c "COPY public" jam-pg17.sql
```

For extra safety, copy the raw PostgreSQL 17 data directory as well. This may need
`sudo`, because the files belong to the container's postgres user:

```shell
cp -a storage/db/postgres storage/db/postgres17-backup
```

### 2. Switch the compose file

Change `docker-compose.yml` as described [above](#2-switch-to-postgresql-19), then:

```shell
mkdir -p storage/db/postgres19
docker compose up -d postgres
docker compose logs postgres
```

Wait for `database system is ready to accept connections`. On this first start,
PostgreSQL 19 creates an empty database and user from `JAM_DB_NAME`, `JAM_DB_USER` and
`JAM_DB_PASSWORD` in your `.env`.

### 3. Import your data

```shell
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d postgres' < jam-pg17.sql
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ANALYZE;"'
```

You will see errors like `role "jam" already exists` and `database "jam" already
exists`. These are expected and harmless: the first start in step 2 already created
both. Any other `ERROR:` line needs a closer look, see
[Troubleshooting](#troubleshooting).

### 4. Start Jam

```shell
docker compose up -d
docker compose logs -f jam
```

## Check that it worked

```shell
scripts/postgres-upgrade.sh verify 19
```

This prints the server version, confirms it really is the major version you asked for,
and lists the row counts of your largest tables. You can also check by hand:

```shell
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select version();"'
```

Then log in to Jam and confirm that your users, media roots, playlists and play history
are all there and that browsing the library works. `docker compose logs jam` should
show no database or connection errors.

## Rollback

If anything goes wrong, go back to PostgreSQL 17. Its data directory has not been
changed.

1. `docker compose down`
2. Set the `postgres` service in `docker-compose.yml` back to:
   ```yaml
       image: postgres:17.12
       volumes:
         - type: bind
           source: ./storage/db/postgres
           target: /var/lib/postgresql/data
   ```
3. `docker compose up -d`

Anything you changed in Jam while it was running on 19 is not in the 17 database.

## Cleanup

Once Jam has run on PostgreSQL 19 for a while and you are sure everything is fine,
delete the old data. This may need `sudo`:

```shell
rm -rf storage/db/postgres storage/db/postgres17-backup
```

Keep `jam-pg17.sql` somewhere safe or delete it. It contains password hashes and all of
your Jam data.

## Troubleshooting

**"already exists" errors during the import.** Expected, see step 3. To import without
them, export and import only the Jam database instead of the whole server:

```shell
docker compose exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USER" -Fc "$POSTGRES_DB"' > jam-pg17.dump
# ... switch to 19 ...
docker compose exec -T postgres sh -c 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner' < jam-pg17.dump
```

**The container fails right at startup.** Check the mount path. With PostgreSQL 18 and
newer the volume belongs at `/var/lib/postgresql`, not `/var/lib/postgresql/data`.

**You switched the compose file before exporting.** No data is lost. PostgreSQL 19
started on the new, empty `storage/db/postgres19`, and your 17 data is still in
`storage/db/postgres`. Set the compose file back to 17 as under
[Rollback](#rollback), empty `storage/db/postgres19`, and start again from step 1.

**Jam cannot log in to the database.** Since PostgreSQL 14 the default password method
is `scram-sha-256`. The export keeps the role's password hash and Jam's driver supports
SCRAM, so this normally needs no change. Check that `JAM_DB_PASSWORD` in `.env` has not
changed.

**Later minor updates.** Moving from `19` to `19.2` is a normal
`docker compose pull` and needs no export and import. Only major version changes do.

## File names and paths

The helper script derives its file names from the version numbers you give it, so
nothing is tied to 17 and 19:

| What | Default | Override with |
| --- | --- | --- |
| Export file | `jam-pg<from>.sql` | `DUMP_FILE` |
| New data directory | `storage/db/postgres<to>` | `DATA_DIR` |
| Import log | `jam-pg<to>-restore.log` | `RESTORE_LOG` |
| Database service | detected | `DB_SERVICE` |
| Jam service | detected | `JAM_SERVICE` |

The script reads your `docker-compose.yml` itself and works out which service is the
database and which is Jam, from the images they use. It prints what it found before it
does anything:

```
Services: database 'postgres', jam 'jam'
```

So renamed services need no extra arguments. It uses the same file `docker compose`
would: `compose.yaml`, `compose.yml`, `docker-compose.yaml` or `docker-compose.yml`,
and `COMPOSE_FILE` if you set it. Override files are not merged, so if a second compose
file renames your services, name them yourself.

If your compose file has two database services, or the script cannot tell which is
which, it says so and stops without changing anything. You can then name them:

```shell
DB_SERVICE=db JAM_SERVICE=music scripts/postgres-upgrade.sh dump 17
```

For example, to read an export from somewhere else:

```shell
DUMP_FILE=/backup/jam.sql scripts/postgres-upgrade.sh restore 17 19
```

Run `scripts/postgres-upgrade.sh` without arguments for the full list of commands.
