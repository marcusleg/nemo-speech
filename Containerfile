# syntax=docker/dockerfile:1

# A CPU-only NeMo-Speech.cpp server with the Nemotron 3.5 ASR model baked in,
# so the container needs no network access at run time. NVIDIA publishes
# release tarballs but no container image.
ARG NEMO_SPEECH_VERSION=0.3.0

FROM docker.io/library/debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS fetch
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# The release's own .sha256 file verifies the tarball, as upstream's
# install.sh does.
ARG NEMO_SPEECH_VERSION
RUN set -eu; \
    archive="nemo-speech-${NEMO_SPEECH_VERSION}-linux-x86_64-cpu.tar.gz"; \
    base="https://github.com/NVIDIA/NeMo-Speech.cpp/releases/download/v${NEMO_SPEECH_VERSION}"; \
    cd /tmp; \
    curl -fsSL --retry 3 -o "$archive" "$base/$archive"; \
    echo "$(curl -fsSL --retry 3 "$base/$archive.sha256" | awk 'NR == 1 { print $1 }')  $archive" | sha256sum -c -; \
    mkdir /opt/nemo-speech; \
    tar -xzf "$archive" -C /opt/nemo-speech --strip-components=1; \
    /opt/nemo-speech/bin/nemo-speech --version

# The model is pinned to a Hugging Face commit and its LFS SHA-256.
ARG MODEL_REPO=nvidia/nemotron-3.5-asr-streaming-0.6b
ARG MODEL_REVISION=ea30d66debe3740a08b573244286791d423d6b3e
ARG MODEL_FILE=nemotron-3.5-asr-streaming-0.6b.q8_0.gguf
ARG MODEL_SHA256=3fc991d3badad7277c11030a7519832cddaf2057aafed6d4b25147e953a070b1
RUN set -eu; \
    mkdir /models; \
    curl -fsSL --retry 3 -o "/models/$MODEL_FILE" \
        "https://huggingface.co/$MODEL_REPO/resolve/$MODEL_REVISION/$MODEL_FILE"; \
    echo "$MODEL_SHA256  /models/$MODEL_FILE" | sha256sum -c -

FROM docker.io/library/debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2
COPY --from=fetch /opt/nemo-speech /opt/nemo-speech
COPY --from=fetch /models /models
RUN ln -s /opt/nemo-speech/bin/nemo-speech /usr/local/bin/nemo-speech
ENV HOME=/tmp
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/nemo-speech"]
CMD ["serve", "--host", "0.0.0.0", "--port", "8080", "--no-ui", \
     "--asr-model", "/models/nemotron-3.5-asr-streaming-0.6b.q8_0.gguf"]
