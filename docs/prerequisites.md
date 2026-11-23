# Prerequisites

Install the following to run from source or release packages:

## Required

- Node.js 26 or newer and npm
- [FFmpeg](https://ffmpeg.org/), including `ffprobe`

## Optional

These tools enable fingerprinting and audio repair features:

- [fpcalc](https://github.com/acoustid/chromaprint/releases/)
- [mp3val](http://mp3val.sourceforge.net/)
- [FLAC](https://xiph.org/flac/)

## Debian/Ubuntu

Install FFmpeg and the optional audio tools with:

```shell
apt-get install ffmpeg libchromaprint-tools mp3val flac
```

## macOS

Install FFmpeg and the optional `fpcalc` and FLAC tools with [Homebrew](https://brew.sh/):

```shell
brew install ffmpeg chromaprint flac mp3val
```

## Tool paths

The audio tools must be on `PATH`, or their paths can be configured individually:

| Tool | Environment variable |
| --- | --- |
| `ffmpeg` | `FFMPEG_PATH` |
| `ffprobe` | `FFPROBE_PATH` |
| `fpcalc` | `FPCALC_PATH` |
| `mp3val` | `MP3VAL_PATH` |
| `flac` | `FLAC_PATH` |
