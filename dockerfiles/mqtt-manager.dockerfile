FROM balenalib/amd64-ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        dnsutils \
        expect \
        mosquitto-clients \
        python3 \
        python3-pip \
        xxd 

COPY applications/mqtt-manager/src/send_message.sh /src/send_message.sh
COPY applications/mqtt-manager/src/auth_monitor.sh /src/auth_monitor.sh

COPY shared_libs /install/shared_libs

WORKDIR /install/shared_libs/message

RUN pip3 install .

WORKDIR /src/

CMD balena-idle


