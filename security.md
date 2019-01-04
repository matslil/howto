Terminology
===========

- Authentication
- Non-repudiation
- Confidentiality
- Data integrity

Mehods
======

- Signature

    - Hash
      Just a checksum of the message. Used primarily for transmission error detection. But if checksum can be provided in a safe way, then it can also verify data integrity.

    - Message authentication code (MAC)
      Message is encrypted using a symmetric algorithm. Only part of the encrypted result is saved, which means that it will not be able to retrieve the original message from the resulting code, but it is enough to verify that the message is intact. Requires knowledge of the shared key when verifying.

    - Hashing message authentication code (HMAC)
      A variant of MAC where the shared key is mixed into the message, and then an message digest (hash) is calculated. Still requires knowledge of the shared key when verifying.

    - Digital signature
      A checksum is calculated. The checksum is then encrypted using an assymetric algorithm, using the private key. This means that the verifier can perform same checksum calculation, and then decrypt the checksum provided with the message using the public key, and verify that it is the same as the verifier calculated.

- Encryption

    - Symmetric encryption
      Uses same key for encryption as well as decryption. Fast, thought to be resistant to quantum computer attacks, smaller keys required. Requires that a key is being shared, which is a big problem.

    - Assymetric encryption
      Uses key pairs. If encrypting with one key in the pair, the other decrypts. Works both ways, i.e. if key A in the pair encrypts the message, key B will decrypt, and vice versa.
      Simplifies key handling since one key can be made public, while keeping the other key private.

- Steganography

    Hide information in something else, e.g. a picture, video or audio.

Hashing
=======

- Checksum

- Hash

- Cryptographic hash

    - MAC

    - HMAC

    - Digital signature

- Making it safer

    - Salting

Key exchange
============

- Certificate authorities

    Place trust on a trustworthy organization or individual.

- Web of trust

    Create chains of trust. Requires that you trust someone, and also trust that this someone actually has some "omdöme" in regard of who he or she in turn trusts.

- Blockchain-based PKI

    Does not provide any assurance that people are who they say they are, but provides assurance that an identity isn't being changed.

Transmission using assymetric algorithms
========================================

- Tripple-wrapped messages

    Signed, encrypted, and signed again. First signature proves who wrote the signature. Second signature proves who encrypted the message.

Storing keys
============

- Blinding mask

    Means you have to take an extra step to get the key, i.e. retrieve the blinding mask as well as the key. Protects against simple memory scans where the attacker does not know where the keys are, but only tries the data found assuming they are keys.

- Checksumming

    Protects against modification attacks, e.g. done by lasers.

- Encrypted storage

    Using hardware assisted encrypted memory storage.


