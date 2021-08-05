FROM balenalib/amd64-ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        dnsutils \
        python3 \
        python3-pip \
        xxd

COPY shared_libs /install/shared_libs

WORKDIR /install/shared_libs/message

RUN pip3 install .

CMD balena-idle