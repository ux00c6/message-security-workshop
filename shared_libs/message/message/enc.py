"""Encryption functions."""
import os
import secrets

from cryptography import x509
from jwcrypto.jwe import JWE
from jwcrypto.jwk import JWK

from .util import Util


class Enc:
    @classmethod
    def encrypt(cls, path_to_certificate, message):
        """Return JWE.
        
        Args:
            path_to_certificate (str): Path to certificate PEM file.
            message (str): Message contents.    
        
        Returns:
            str: Encrypted message, as a serialized JWE.
        """

        pubkey_pyca = x509.load_pem_x509_certificate(Util.get_file_contents(path_to_certificate)).public_key()
        public_key = JWK()
        public_key.import_from_pyca(pubkey_pyca)
        
        protected_header = {"alg": "RSA-OAEP-256",
                            "enc": "A256CBC-HS512",
                            "typ": "JWE"}
        jwetoken = JWE(message.encode("utf-8"), recipient=public_key, protected=protected_header)
        return jwetoken.serialize()

    @classmethod
    def decrypt(cls, path_to_private_key, encrypted_message):
        """Extract and return a message from an encrypted object.
        
        Args:
            path_to_private_key (str): Absolute path to private key file.
            message (str): Encrypted messsage, base64-encoded.
        
        Returns:
            str: Decrypted message.
        """
        privkey_pem = Util.get_file_contents(path_to_private_key)
        private_key = JWK()
        private_key.import_from_pem(privkey_pem)
        token = JWE()
        token.deserialize(encrypted_message, key=private_key)
        return token.payload.decode()