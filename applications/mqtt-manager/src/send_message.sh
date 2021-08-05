#!/bin/bash
# Encode and send a message over MQTT


# Set vars from args
MESSAGE=$2
RECIPIENT=$1

USAGE_ERR="Args: Recipient Message"

if [ -z "${MESSAGE}" ]
then
  echo "${USAGE_ERR}"
  exit 1
fi

if [ -z "${RECIPIENT}" ]
then
  echo "${USAGE_ERR}"
  exit 1
fi


# Get the public identity
/install/shared_libs/scripts/cache_public_identity.sh ${RECIPIENT}

ENCODED_MESSAGE=$(jose_encode ${RECIPIENT} "${MESSAGE}")

mosquitto_pub -h ${MQTT_HOST} -p ${MQTT_PORT} -t ${RECIPIENT} -m ${ENCODED_MESSAGE}

