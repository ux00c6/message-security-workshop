FROM balenalib/amd64-ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        curl \
        dnsutils \
        openssl \
        xxd

COPY applications/identity-manager/src /src
COPY shared_libs/scripts/cache_public_identity.sh /src/

WORKDIR /src

CMD balena-idle
