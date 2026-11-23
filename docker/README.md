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
