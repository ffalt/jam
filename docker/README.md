# Jam Docker image development

See the [root README](../README.md) for deployment and usage. Run these build commands from the repository root.

## Single platform build

The `ffalt/jam` image is built from the sources in this repo, so the build context is the repo root.

```shell
docker build -f docker/jam/Dockerfile -t ffalt/jam .
docker tag ffalt/jam ffalt/jam:test
```

## Multi platform build

```shell
docker buildx build --platform linux/amd64,linux/arm64 -f docker/jam/Dockerfile -t ffalt/jam .
```

## Test image build

```shell
docker buildx build -t ffalt/jam-test ./docker/test/
docker tag ffalt/jam-test ffalt/jam-test:test
```

## Compose deployment stack

`compose/` holds the Docker Compose stack (`ffalt/jam:latest` plus PostgreSQL), the
configuration templates and the empty storage folders users deploy into. The release workflow
packs it as the `jam-docker.zip` release asset, with the root `LICENSE` and a pre-created
`storage/db/postgres` directory. The deployment guide is [docs/docker.md](../docs/docker.md).

To test the packaging locally:

```shell
mkdir -p local/package/jam
cp -R docker/compose/. local/package/jam/
rm -f local/package/jam/.gitignore
cp LICENSE local/package/jam/LICENSE
mkdir -p local/package/jam/storage/db/postgres
(cd local/package && zip -r ./jam-docker.zip jam)
```
