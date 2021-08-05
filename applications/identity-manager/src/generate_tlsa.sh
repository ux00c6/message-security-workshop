#!/bin/bash

openssl x509 \
    -in ${IDENTITY_DIR}/${IDENTITY_NAME}.cert.pem \
    -out ${IDENTITY_DIR}/${IDENTITY_NAME}.cert.der \
    -outform DER 
echo "TLSA record:"
echo "3 0 0 $(cat ${IDENTITY_DIR}/${IDENTITY_NAME}.cert.der | xxd -p -c 1024)"