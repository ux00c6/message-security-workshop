import os
import re
from setuptools import setup

setup(name="message",
      version="0.1",
      author="Ash",
      author_email="ash@example",
      description="JWE/JWS using RSA keys and certs.",
      license="BSD",
      keywords="jwe jws",
      packages=["message", "message.scripts"],
      entry_points={
          "console_scripts": [
              "jose_decode = message.scripts.decode:main",
              "jose_encode = message.scripts.encode:main"
          ]},
      install_requires=["jwcrypto>=0.7,<2.0"],
      classifiers=[],)