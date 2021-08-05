"""Signing and verification functions."""

from jwcrypto.jwk import JWK
from jwcrypto.jws import JWS

from .util import Util

class Sign:
    @classmethod
    def sign(cls, private_key_path, dns_identity_name, message):
        privkey_pem = Util.get_file_contents(private_key_path)
        privkey_jwk = JWK()
        privkey_jwk.import_from_pem(privkey_pem)
        protected = {"alg": "RS256", "x5u": dns_identity_name}
        jwstoken = JWS(message.encode('utf-8'))
        jwstoken.add_signature(privkey_jwk, None, protected)
        return jwstoken.serialize()

    @classmethod
    def verify(cls, certificate_base_path, message):
        jws_token = JWS()
        jws_token.deserialize(message)
        dns_name = jws_token.jose_header["x5u"]
        pubkey = JWK()
        pyca_pubkey = Util.get_pubkey_from_cert(dns_name, certificate_base_path)
        pubkey.import_from_pyca(pyca_pubkey)
        jws_token.verify(pubkey)
        return jws_token.payload