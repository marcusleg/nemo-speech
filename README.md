# nemo-speech

A CPU-only container image of [NeMo-Speech.cpp](https://github.com/NVIDIA/NeMo-Speech.cpp)'s
`nemo-speech serve`, with the
[Nemotron 3.5 ASR Streaming 0.6B](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b)
q8_0 GGUF baked in. NVIDIA publishes release tarballs but no image, and the upstream Dockerfile
builds for CUDA.

The image needs no network access at run time. It serves OpenAI's `/v1/audio/transcriptions` on
port 8080 and runs as UID 65532.

```sh
podman run --rm -p 8080:8080 ghcr.io/marcusleg/nemo-speech:0.3.0
curl http://127.0.0.1:8080/v1/audio/transcriptions \
    -F model=nemotron-3.5-asr-streaming-0.6b.q8_0 -F file=@command.wav
```

The model detects the spoken language (40 locales, including German and English) when the
request has no `language`, or an empty one. Any language it knows, including a bare `en`, forces
that language, so a client that always sends one loses detection.

## Contents

| | Pinned by |
|---|---|
| NeMo-Speech.cpp CPU release for linux/x86_64 | `NEMO_SPEECH_VERSION`, verified against the release's `.sha256` file |
| `nemotron-3.5-asr-streaming-0.6b.q8_0.gguf` | `MODEL_REVISION` (Hugging Face commit) and `MODEL_SHA256` |
| Debian trixie-slim | digest |

## Releasing

Push a tag that names the `NEMO_SPEECH_VERSION` in the `Containerfile`, such as `v0.3.0`.
A rebuild of the same version (a new model or base image) adds a suffix, such as `v0.3.0-2`.
The release workflow smoke-tests the image and publishes `ghcr.io/marcusleg/nemo-speech:<version>`.

```sh
scripts/smoke-test-image.sh <image>   # CONTAINER_ENGINE=podman to use podman
```

## Licenses

The files in this repository are MIT-licensed. NeMo-Speech.cpp is Apache-2.0; its license and
third-party notices ship in the image under `/opt/nemo-speech/share`. The Nemotron model is
licensed under [OpenMDW-1.1](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b).
