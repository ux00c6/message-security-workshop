# message-security-workshop

Technical content for DC29 workshop: Secure messaging over unsecured transports

## Requirements

* Docker engine
* Docker compose
* A DNS server (or hosted service) which supports the TLSA resource record type, and configured for DNSSEC.

## Getting started

* Clone the repository locally and enter the repo's root directory.
* Copy the `.env.example` file to `.env` and complete the `.env` file:
  * `TRUSTED_DOMAINS`: This is a comma-separated list of domains you authorize to send you messages. This should contain your domain name.
  * `IDENTITY_NAME`: This is the DNS name where you'll host your TLSA record.
  * `MQTT_HOST`: This setting will be provided in the workshop.
  * `MQTT_PORT`: This wetting will be provided in the workshop.
  * `DNS_RESOLVER`: This is set to 1.1.1.1 by default. Feel free to set to your personal favorite.
* Run `docker-compose up --build -d && docker-compose logs -f` and wait while the application builds

## Bootstrapping Identity

### Create your key pair

`docker exec -it identity-manager ./generate_selfsigned_identity.sh`

This is verbose. You'll see the metadata from the generated certificate scroll by.

### Generate your TLSA record

`docker exec -it identity-manager ./generate_tlsa.sh`

This will generate a TLSA record, which you should configure in your DNS server at `${IDENTITY_NAME}`

## Messaging

### Loopback test

`docker exec -it identity-manager ./cache_public_identity.sh`

This will attempt to retrieve and parse your TLSA record from DNS.

### Send a message to someone else

Update your `.env` file to include your messaging peer's DNS domain in addition to your own.

`ctrl-c` your log tail from earlier and run `docker-compose up --build -d && docker-compose logs -f` again.

Run `docker exec -it  mqtt-sender ./send_message.sh RECIPIENT_DNS_NAME "THIS IS A TEST MESSAGE"`

## What's Included

This workshop explores E2E message security (signing and encryption), using DNS as the identity namespace and public key lookup mechanism.

Much of this is implemented with shell scripts, with some Python used for message formatting and encapsulation (JOSE).

The structure of this application is intended to facilitate easy hacking/replacement of components to adapt to other transports.

### Containers

#### identity-manager

This container has tools for managing credentials, like generating key/cert and producing a formatted TLSA record.

#### mqtt-monitor

This container listens on your MQTT topic, and shows all messages that appear on the topic.

#### mqtt-parser

This container listens on your MQTT topic, like `mqtt-monitor`, but additionally attempts to decrypt and verify messages appearing on your topic.

#### message-codec

This container is a sort of utility container, which provides easy access to the `jose_encode` and `jose_decode` tools.

#### mqtt-sender

This container is used when sending messages over MQTT. See example above.

### Scripts and Libraries

* `shared_libs/message`: This is a Python library which wraps JWE and JWS message security functionality.
* `shared_libs/scripts/cache_public_identity.sh`: This script uses DNS to acquire an entity certificate. This script also performs validation on what we get from DNS.

## Misc Notes

This is not production-ready code. Far from it. This repo is only intended to be a collection of tools and libraries for exploring E2E message security in a lab environment.