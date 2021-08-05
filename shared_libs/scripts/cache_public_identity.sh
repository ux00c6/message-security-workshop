#!/bin/bash

PUBLIC_IDENTITY_NAME=$1

mkdir -p ${IDENTITY_DIR}

ERR_NOSAN="Identity name not found in certificate SAN!"

IDENTITY_CERT_PATH=${IDENTITY_DIR}/${PUBLIC_IDENTITY_NAME}.cert.pem

# Get the output from dig
DIG_OUT="$(dig @${DNS_RESOLVER} -t TLSA ${PUBLIC_IDENTITY_NAME} +dnssec)"

echo "${DIG_OUT}"

DNSSEC_OK="FALSE"
NOSAN="FALSE"
CERT_VALID="UNVERIFIED"

# Get the query flags from the dig output 
FLAGS=$(echo "${DIG_OUT}" | grep "; flags:")
echo "${FLAGS}" | awk -F\; '{print $3}' | grep " ad" && DNSSEC_OK=TRUE
echo "Was DNSSEC used?  ${DNSSEC_OK}"

# Get the TLSA record from the response, process into something we can more easily work with.
FULL_RESPONSE=$(echo -e "${DIG_OUT}" |grep -v "RRSIG" | grep "^${PUBLIC_IDENTITY_NAME}" | tr -s ' ' | tr '\t' ' ')
FULL_TLSA=$(echo "${FULL_RESPONSE}" | awk -F'TLSA' '{print $2}' )
TLSA=$(echo "${FULL_TLSA}" | cut -d ' ' -f 5-99 | sed -e 's/ //g')
echo "FULL_RESPONSE: ${FULL_RESPONSE}"
echo "FULL_TLSA: ${FULL_TLSA}"
echo "TLSA: ${TLSA}"

# If DNSSEC was used, we can populate the identity PEM file and be done with it.
if [ "${DNSSEC_OK}" = "TRUE" ]
then 
    echo "We will write the cert in PEM format to ${IDENTITY_CERT_PATH}"
    echo "TLSA: ${TLSA}"
    echo ${TLSA} | xxd -r -p | openssl x509 -inform DER > ${IDENTITY_CERT_PATH}

# If DNSSEC was not used, we proceed with alternative validation
else
    CERT_DER_B64=$(echo ${TLSA} | xxd -r -p | base64 -w 0)
    CERT_META=$(echo ${CERT_DER_B64} | base64 -d | openssl x509 -inform DER -noout -text)
    
    # Print the certificate metadata.
    echo "${CERT_META}"
    echo "${CERT_META}" | grep "DNS:${PUBLIC_IDENTITY_NAME}$" || NOSAN=TRUE 

    #If there's no match between the cert's SAN and the name we used to query DNS, exit.
    if [ "${NOSAN}" = "TRUE" ]
    then
        echo "${ERR_NOSAN}" && exit 1
    fi

    # Get the authorityKeyID from the certificate
    AKI=$(echo "${CERT_META}" | grep -A1 "X509v3 Authority Key Identifier:" | tail -1 | sed -e "s/keyid://" -e "s/:/-/g" -e "s/ //g")

    # Extract the hostname to build the URL
    URL_HOSTNAME=$(echo "${PUBLIC_IDENTITY_NAME}" | awk -F_ '{print $2}' | sed -e 's/_//')

    # Compose the URL, including the AKI
    URL="https://${URL_HOSTNAME}/${AKI,,}.pem"


    echo "Attempt to find cert responsible for signing ${PUBLIC_IDENTITY_NAME} with AKI ${AKI} at ${URL}"
    
    # Download the certificate from the web server
    WEB_PEM=$(curl --fail --show-error ${URL} || echo "PEMFAIL" )

    # Make sure the response is actually a certificate
    echo "${WEB_PEM}" | openssl x509 -noout -text > /dev/null || WEB_PEM="PEMFAIL"
    if [ "${WEB_PEM}" = "PEMFAIL" ]
    then
        echo "Failed to find PEM certificate at ${URL}" && exit 1
    fi

    # Check that the PEM file from the web validates the certificate from the TLSA record
    openssl verify -verbose -CAfile <(echo "${WEB_PEM}") <(echo "${CERT_DER_B64}" | base64 -d | openssl x509 -inform DER ) || CERT_VALID="FALSE"
    if [ "${CERT_VALID}" = "FALSE" ]
    then
        echo "Failed to validate TLSA with ${URL}" && exit 1
    fi
    echo "${IDENTITY_CERT_PATH}"

    # Finally, write the validated cert to disk.
    echo "${CERT_DER_B64}" | base64 -d | openssl x509 -inform DER > "${IDENTITY_CERT_PATH}"
fi

echo "Done!"