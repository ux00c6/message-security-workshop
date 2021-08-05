"""Utility functions."""

import os
from cryptography import x509

class Util:
    @classmethod
    def get_file_contents(cls, file_path):
        """Return the contents of a file."""
        with open(file_path, "rb") as fp:
            return fp.read()

    @classmethod
    def get_pubkey_from_cert(cls, dns_name, certificate_base_path):
        """Return the public key from a certificate."""
        file_name = "{}.cert.pem".format(dns_name)
        file_path = os.path.join(certificate_base_path, file_name)
        try:
            file_contents = cls.get_file_contents(file_path)
        except OSError as err:
            raise ValueError("Trouble finding certificate file, does it exist? {}".format(err))
        cert_obj = x509.load_pem_x509_certificate(file_contents)
        return cert_obj.public_key()