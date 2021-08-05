#!/bin/bash

mkdir -p ${IDENTITY_DIR}

ALGORITHM=RSA
PRIVATE_KEY_FILE=${IDENTITY_DIR}/${IDENTITY_NAME}.key.pem
CERTIFICATE_FILE=${IDENTITY_DIR}/${IDENTITY_NAME}.cert.pem

openssl genpkey \
    -algorithm ${ALGORITHM} > ${PRIVATE_KEY_FILE}

openssl req \
    -x509 \
    -key ${PRIVATE_KEY_FILE} \
    -out ${CERTIFICATE_FILE} \
    -days 365 \
    -sha256 \
    -subj "/CN=${IDENTITY_NAME}" \
    -addext "subjectAltName=DNS:${IDENTITY_NAME}" \
    -nodes

echo "Self-signed identity generated."
echo "Private key: ${PRIVATE_KEY_FILE}"
echo "Public key: ${CERTIFICATE_FILE}"
echo "Certificate metadata:"
openssl x509 -in ${CERTIFICATE_FILE} -noout -text