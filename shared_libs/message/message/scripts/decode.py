"""This tool signs and encrypts a message, and prints it in base64 to STDOUT."""
import base64
import os
import re
import subprocess
import sys
from argparse import ArgumentParser

from jwcrypto.jws import JWS

from message import Sign
from message import Enc


def main():
    identity_name = os.getenv("IDENTITY_NAME")
    identity_path_env = os.getenv("IDENTITY_DIR")
    trusted_domains = os.getenv("TRUSTED_DOMAINS")
    # Parse args
    args = ArgumentParser(description="Encapsulate a message for a recipient.")
    args.add_argument("message", default=sys.stdin, help="The message to be decoded.")
    args.add_argument("--identitydir", default=identity_path_env, help="Override path to identity directory.")
    args.add_argument("--selfid", default=identity_name, help="Override own detected identity name")
    args.add_argument("--idgetter", default="/install/shared_libs/scripts/cache_public_identity.sh", help="Override path for identity caching tool.")
    arguments = args.parse_args()
    privkey_path = "{}.key.pem".format(os.path.join(arguments.identitydir, arguments.selfid))
    # Sanity check for args
    if not os.path.exists(privkey_path):
        print("Private key file does not exist at {}".format(privkey_path))
    # Unpack base64
    unpacked = base64.b64decode(arguments.message)
    # Decrypt message
    signed = Enc.decrypt(privkey_path, unpacked)
    # Get the sender's DNS name and sanitize
    jws_token = JWS()
    jws_token.deserialize(signed)
    dns_name = sanitize_dns_name(jws_token.jose_header["x5u"])
    if trusted_domains:
        if not dns_name_in_domains(dns_name, trusted_domains):
            print("{} not in trusted domains!".format(dns_name))
            sys.exit(1)
    cert_file_name = "{}.cert.pem".format(dns_name)
    cert_path = os.path.join(arguments.identitydir, cert_file_name)
    if not os.path.exists(cert_path):
        print("Certificate does not exist at {}, attempt to cache from DNS...".format(cert_path))
        subprocess.call([arguments.idgetter, dns_name])
    try:
        message = Sign.verify(arguments.identitydir, signed)
    except ValueError as err:
        print(err)
        print("Unable to verify message from {}".format(dns_name))
        sys.exit(1)
    print("{} sent a message: {}".format(dns_name, message))


def sanitize_dns_name(dns_name):
    labels = dns_name.lower().strip(".").split(".")
    for label in labels:
        if not re.match(r'^[a-z0-9_-]+$', label):
            print("DNS name failed sanitizing: {}".format(dns_name))
        if not len(label) < 64:
            print("DNS label too long: {} in name {}".format(label, dns_name))
    sanitized = ".".join(labels)
    if not len(sanitized) < 254:
        print("DNS name too long: {}".format(sanitized))
    return sanitized


def dns_name_in_domains(dns_name, domains):
    dns_name_labels = dns_name.split(".")
    for domain in domains:
        dom_labels = domain.split(".")
        if len(dom_labels) >= len(dns_name_labels):
            continue
        if dns_name_labels[-abs(len(dom_labels)):] == dom_labels:
            return True
    return False

    


if __name__ == "__main__":
    main()