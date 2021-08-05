#!/bin/bash
# Monitor MQTT for encrypted and authenticated messages

unbuffer mosquitto_sub -h ${MQTT_HOST} -p ${MQTT_PORT} -t ${IDENTITY_NAME} | xargs -n1 jose_decode