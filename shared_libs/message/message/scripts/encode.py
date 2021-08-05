"""This tool signs and encrypts a message, and prints it in base64 to STDOUT."""
import base64
import os
from argparse import ArgumentParser

from message import Sign
from message import Enc


def main():
    identity_name = os.getenv("IDENTITY_NAME")
    identity_path_env = os.getenv("IDENTITY_DIR")
    # Parse args
    args = ArgumentParser(description="Encapsulate a message for a recipient.")
    args.add_argument("recipient", help="DNS name of recipient.")
    args.add_argument("message", help="The message to be encapsulated.")
    args.add_argument("--identitydir", default=identity_path_env, help="Override path to identity directory.")
    args.add_argument("--selfid", default=identity_name, help="Override own detected identity name")
    arguments = args.parse_args()
    privkey_path = "{}.key.pem".format(os.path.join(arguments.identitydir, arguments.selfid))
    cert_path = "{}.cert.pem".format(os.path.join(arguments.identitydir, arguments.recipient))
    # Sanity check for args
    if not os.path.exists(privkey_path):
        print("Private key file does not exist at {}".format(privkey_path))
    if not os.path.exists(cert_path):
        print("Recipient's certificate file does not exist at {}".format(privkey_path))
    # Generate signed message
    signed = Sign.sign(privkey_path, arguments.selfid, arguments.message)
    # Encrypt message
    encrypted = Enc.encrypt(cert_path, signed)
    # Print out Base64
    final = base64.b64encode(encrypted.encode())
    print(final.decode())

if __name__ == "__main__":
    main()