#!/usr/bin/env bash
# Helper for a PostgreSQL major version upgrade of the Jam compose stack
# (see docs/postgres-upgrade.md).
set -euo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
cd "$(dirname "$SELF")/.."

# Defaults. Override with the command arguments, or with these as environment
# variables. FROM_MAJOR is the version you are leaving, TO_MAJOR the one you move to.
FROM_MAJOR="${FROM_MAJOR:-17}"
TO_MAJOR="${TO_MAJOR:-19}"
WAIT_SECONDS="${WAIT_SECONDS:-120}"

# Service names in your docker-compose.yml. Left empty they are detected from the
# images the compose file uses.
DB_SERVICE="${DB_SERVICE:-}"
JAM_SERVICE="${JAM_SERVICE:-}"

die() { echo "error: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

usage() {
  cat <<MSG
Helper for a PostgreSQL major version upgrade (see docs/postgres-upgrade.md).

  scripts/postgres-upgrade.sh dump    [from]      export, while still on <from>
  scripts/postgres-upgrade.sh restore [from] [to] import, after switching to <to>
  scripts/postgres-upgrade.sh verify  [major]     show server version and row counts

Defaults: from=$FROM_MAJOR, to=$TO_MAJOR. Paths follow the versions:

  dump file   jam-pg<from>.sql          override with DUMP_FILE
  data dir    storage/db/postgres<to>   override with DATA_DIR
  restore log jam-pg<to>-restore.log    override with RESTORE_LOG

The database and jam services are read from the compose file itself. Set DB_SERVICE
or JAM_SERVICE to name them yourself.

Examples:
  scripts/postgres-upgrade.sh dump 17
  scripts/postgres-upgrade.sh restore 17 19
  DUMP_FILE=/backup/jam.sql scripts/postgres-upgrade.sh restore 17 19
MSG
}

require_major_arg() {
  case "$1" in
    ''|*[!0-9]*) die "'$1' is not a PostgreSQL major version" ;;
  esac
}

resolve_paths() {
  DUMP_FILE="${DUMP_FILE:-jam-pg${FROM_MAJOR}.sql}"
  DATA_DIR="${DATA_DIR:-storage/db/postgres${TO_MAJOR}}"
  RESTORE_LOG="${RESTORE_LOG:-jam-pg${TO_MAJOR}-restore.log}"
}

# The compose file in the current directory, in the order docker compose uses.
# Resolved once, from the main shell, so that a missing file can actually exit:
# a die() inside a $(...) would only end the subshell.
COMPOSE_YML=""
resolve_compose_file() {
  local f
  for f in ${COMPOSE_FILE:-compose.yaml compose.yml docker-compose.yaml docker-compose.yml}; do
    if [ -f "$f" ]; then COMPOSE_YML="$f"; return 0; fi
  done
  die "no compose file in $PWD
Run this from the folder that holds your docker-compose.yml, or set COMPOSE_FILE."
}

compose_file() { printf '%s' "$COMPOSE_YML"; }

# Reads the services out of the compose file as "name<tab>image" lines.
parse_compose() {
  awk '
    { line = $0; sub(/\r$/, "", line) }
    line ~ /^[[:space:]]*#/ { next }
    line ~ /^[[:space:]]*$/ { next }
    {
      body = line
      sub(/^[[:space:]]*/, "", body)
      indent = length(line) - length(body)
    }
    indent == 0 {
      in_services = (body ~ /^services:/)
      service = ""
      service_indent = -1
      next
    }
    !in_services { next }
    (service_indent == -1 || indent == service_indent) && body ~ /^[A-Za-z0-9._-]+:/ {
      service_indent = indent
      service = body
      sub(/:.*/, "", service)
      order[++count] = service
      image[service] = ""
      next
    }
    indent > service_indent && service != "" && body ~ /^image:[[:space:]]*/ {
      if (image[service] == "") {
        value = body
        sub(/^image:[[:space:]]*/, "", value)
        sub(/[[:space:]]+#.*$/, "", value)
        gsub(/^["'"'"']|["'"'"']$/, "", value)
        image[service] = value
      }
    }
    END { for (i = 1; i <= count; i++) print order[i] "\t" image[order[i]] }
  ' "${COMPOSE_YML:-/dev/null}" < /dev/null
}

# All service names in the compose file.
compose_services() {
  local services
  services="$(parse_compose | cut -f1)"
  [ -n "$services" ] || die "no services found in $(compose_file)"
  printf '%s\n' "$services"
}

# Every service whose image matches one of the space separated globs in $1.
services_matching_image() {
  local patterns="$1" name image pattern found=""
  # no pathname expansion below: '*jam*' must stay a pattern and must not turn
  # into the name of a file that happens to sit in this directory, such as the
  # jam-pg17.sql this script writes itself
  set -f
  while IFS="$(printf '\t')" read -r name image; do
    [ -n "$image" ] || continue
    for pattern in $patterns; do
      # shellcheck disable=SC2254
      case "$image" in
        $pattern) found="$found $name"; break ;;
      esac
    done
  done <<EOF
$(parse_compose)
EOF
  set +f
  printf '%s' "${found# }"
}

# Pick one service: an explicit name wins, otherwise detect it by image, otherwise
# fall back to the conventional name. Runs before anything is stopped or started.
#   pick_service <description> <env var> <current> <image glob> <fallback> <exclude> <service>...
pick_service() {
  local kind="$1" var="$2" current="$3" pattern="$4" fallback="$5" exclude="$6"
  shift 6
  local services="$*" candidates="" svc

  if [ -n "$current" ]; then
    printf '%s\n' $services | grep -qx -- "$current" ||
      die "$(compose_file) has no service '$current'.
Services found: $services"
    printf '%s' "$current"
    return
  fi

  for svc in $(services_matching_image "$pattern"); do
    [ "$svc" = "$exclude" ] && continue
    candidates="$candidates $svc"
  done
  candidates="${candidates# }"

  case "$candidates" in
    '')
      if printf '%s\n' $services | grep -qx -- "$fallback"; then
        printf '%s' "$fallback"
      else
        die "cannot tell from $(compose_file) which service is $kind.
Services found: $services
Name it yourself: $var=<service> scripts/postgres-upgrade.sh ..."
      fi ;;
    *' '*)
      die "several services in $(compose_file) could be $kind: $candidates
Name the one you mean: $var=${candidates%% *} scripts/postgres-upgrade.sh ..." ;;
    *) printf '%s' "$candidates" ;;
  esac
}

resolve_services() {
  local services
  resolve_compose_file
  services="$(compose_services | tr '\n' ' ')"

  DB_SERVICE="$(pick_service "the database" DB_SERVICE "$DB_SERVICE" \
    '*postgres* *postgis* *pgvector* *pgautoupgrade*' postgres '' $services)"
  JAM_SERVICE="$(pick_service "jam" JAM_SERVICE "$JAM_SERVICE" \
    '*jam*' jam "$DB_SERVICE" $services)"

  [ "$DB_SERVICE" != "$JAM_SERVICE" ] ||
    die "'$DB_SERVICE' cannot be both the database and jam.
Name them yourself: DB_SERVICE=<service> JAM_SERVICE=<service> scripts/postgres-upgrade.sh ..."

  echo "Services: database '$DB_SERVICE', jam '$JAM_SERVICE'"
}

in_postgres() { docker compose exec -T "$DB_SERVICE" sh -c "$1"; }

server_major() {
  in_postgres 'psql -U "$POSTGRES_USER" -d postgres -XAtc "select current_setting('"'"'server_version_num'"'"')::int / 10000"' | tr -d '\r'
}

wait_until_ready() {
  local waited=0
  until in_postgres 'pg_isready -U "$POSTGRES_USER" -d postgres' >/dev/null 2>&1; do
    [ "$waited" -ge "$WAIT_SECONDS" ] && die "postgres was not ready after ${WAIT_SECONDS}s, check: docker compose logs $DB_SERVICE"
    sleep 2
    waited=$((waited + 2))
  done
}

require_running_major() {
  local want="$1" have
  have="$(server_major)"
  [ "$have" = "$want" ] || die "postgres $have is running, expected $want"
}

cmd_dump() {
  [ "$#" -le 1 ] || { usage; exit 1; }
  if [ "$#" -eq 1 ]; then FROM_MAJOR="$1"; fi
  require_major_arg "$FROM_MAJOR"
  resolve_paths

  [ -s "$DUMP_FILE" ] && die "$DUMP_FILE already exists and is not empty, move it away first"
  resolve_services

  step "Stopping $JAM_SERVICE"
  docker compose stop "$JAM_SERVICE"

  step "Starting postgres $FROM_MAJOR"
  docker compose up -d "$DB_SERVICE"
  wait_until_ready
  require_running_major "$FROM_MAJOR"

  step "Dumping to $DUMP_FILE"
  in_postgres 'pg_dumpall -U "$POSTGRES_USER"' > "$DUMP_FILE.part"
  mv "$DUMP_FILE.part" "$DUMP_FILE"

  local tables
  tables="$(grep -c "^COPY public" "$DUMP_FILE" || true)"
  [ "$tables" -gt 0 ] || die "$DUMP_FILE contains no table data"
  echo "$DUMP_FILE: $(wc -c < "$DUMP_FILE") bytes, $tables tables"

  step "Stopping postgres"
  docker compose stop "$DB_SERVICE"

  cat <<MSG

Dump done. Next:
  1. switch docker-compose.yml to postgres $TO_MAJOR (edit the image tag, and mount
     $DATA_DIR at /var/lib/postgresql for 18 and newer,
     at /var/lib/postgresql/data for 17 and older)
  2. scripts/postgres-upgrade.sh restore $FROM_MAJOR $TO_MAJOR
MSG
}

cmd_restore() {
  [ "$#" -le 2 ] || { usage; exit 1; }
  if [ "$#" -ge 1 ]; then FROM_MAJOR="$1"; fi
  if [ "$#" -ge 2 ]; then TO_MAJOR="$2"; fi
  require_major_arg "$FROM_MAJOR"
  require_major_arg "$TO_MAJOR"
  [ "$TO_MAJOR" -ge "$FROM_MAJOR" ] || die "cannot restore a postgres $FROM_MAJOR dump into the older postgres $TO_MAJOR"
  resolve_paths

  [ -s "$DUMP_FILE" ] || die "$DUMP_FILE is missing or empty, run 'dump $FROM_MAJOR' first"
  grep -q "^COPY public" "$DUMP_FILE" || die "$DUMP_FILE contains no table data"

  resolve_services

  step "Starting postgres $TO_MAJOR"
  mkdir -p "$DATA_DIR"
  docker compose up -d "$DB_SERVICE"
  wait_until_ready
  require_running_major "$TO_MAJOR"

  step "Restoring $DUMP_FILE"
  in_postgres 'psql -U "$POSTGRES_USER" -d postgres' < "$DUMP_FILE" > "$RESTORE_LOG" 2>&1 || true
  local unexpected
  unexpected="$(grep "^ERROR:" "$RESTORE_LOG" | grep -v "already exists" || true)"
  if [ -n "$unexpected" ]; then
    echo "$unexpected" >&2
    die "unexpected errors during restore, full output in $RESTORE_LOG"
  fi
  echo "no unexpected errors (full output in $RESTORE_LOG)"

  step "Running ANALYZE"
  in_postgres 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ANALYZE;"'

  step "Starting the rest of the stack"
  docker compose up -d

  cmd_verify "$TO_MAJOR"
}

cmd_verify() {
  [ "$#" -le 1 ] || { usage; exit 1; }
  local want=""
  if [ "$#" -eq 1 ]; then
    require_major_arg "$1"
    want="$1"
  fi

  resolve_services

  step "Server version"
  in_postgres 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -XAtc "select version();"'
  if [ -n "$want" ]; then
    require_running_major "$want"
    echo "postgres $want confirmed"
  fi

  step "Row counts"
  in_postgres 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select relname, n_live_tup from pg_stat_user_tables order by n_live_tup desc limit 10;"'

  cat <<MSG

Now check: docker compose logs -f $JAM_SERVICE
Then log in and confirm users, media roots, playlists and play history.
MSG
}

command="${1:-}"
[ "$#" -gt 0 ] && shift || true
case "$command" in
  dump) cmd_dump "$@" ;;
  restore) cmd_restore "$@" ;;
  verify) cmd_verify "$@" ;;
  *) usage; exit 1 ;;
esac
