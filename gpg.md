Problems:

- Using multiple Yubikeys for same GPG key
- Having multiple smart card readers
- Outlook 2013 plugin instability

Successes:

- Key signing using scripts
- Decrypt using Android phone
- Decrypt using Claws mail
- Using Yubikey

Tips:

- Policy for signatures
- Turn off unsafe hash algoritms (SHA-1, ??)
- Signing key always use master key.

Quick GPG into
==============

The following web site explains what GPG is:
 -  https://en.wikipedia.org/wiki/GNU_Privacy_Guard

This is the official GPG web site:
 -  https://www.gnupg.org

This is the standard for using GPG with mails:
 -  https://tools.ietf.org/html/rfc4880

The man-page is also a good source of information. I always use "gpg2",
since it has better support for smart cards.

Some things were not that obvious to me from the beginning, so I'll try to
cover them in this chapter. First a nice graph below how things relate to
each other:

![GPG diagram](gpg.svg)

GPG command and keyrings
------------------------

To understand this diagram, start with "gpg" since this is the tool you will
use for managing your keys. The "gpg" command needs at least one public
keyring and one private (secret) keyring. By default there is one each in
~/.gnupg directory, created by "gpg" if it does not exist already. Using
command line option "--keyring" to add a public keyring file,
"--secret-keyring" to add a private keyring file and "--no-default-keyring"
to not use the default public and private keyring files. Note that keyring
file names are relative to ~/.gnupg directory, unless an absolute path is
given.

Keyring server
--------------

Normally you upload your master public key to a keyring server that belongs
to a pool of SKS keyring servers, e.g. by using
"--keyserver pool.sks-keyservers.net" to indicate what server to use. Keys
uploaded to one such key server will eventually be replicated to all the
others.

Note that by uploading the master public key, the public sub-keys will go
with it, which should normally be what you want.

GPG key, private and public
---------------------------

GPG keys come in pair, one private key and one public key. Each such pair
shares the same hash (fingerprint) and thereby also key ID. When talking
about a GPG key, this might sometimes refer to the public key and sometimes
to the key pair, which can be somewhat confusing.

The public key will decrypt what a private key has encrypted, and vice versa.
This means that if you send something, you encrypt using your private key and
the receiver decrypts using your public key. If someone sends something to you
they use your public key to encrypt, and you use your private key to decrypt.

Same applies to signatures, but signing instead of encrypting and verifying
signature instead of decrypting.

Master key vs. sub-key
----------------------

GPG keys have a two level hierarchy where a master key can have any number of
sub-keys. Master and sub-keys can all sign, encrypt and authenticate, but only
master key can certify.

User IDs, i.e. information about the key owner, belongs only to the master key.

User ID
-------

Master key has any number of user IDs, which can be e-mail address or photos.
The e-mail address has the following familiar syntax:

    name (description) <e-mail>

E.g.:

    Anders Andersson (private) <anders.andersson@gmail.com>

The "()" part is optional, but the rest is usually expected to be present.
However, this is free text so this is merely a recommended syntax.

Generate the keys
=================

There are many ways of generating GPG keys, this chapter will only mention one
of them. It is the one I have chosen, and should be good enough for paranoid
people.

The tricky part is to keep the private key data private. These instructions
build on the following mechanism to assure this:

 1. Keys are generated on a computer not connected to a network.
 2. Backup copy of private key data is stored safely, e.g. in a safe.
 3. For usage, private key data is stored on a Yubikey, making copying
    impossible.

These instructions have been greatly influenced by Simon Josefsson's blog
[Offline GnuPG Master Key and Subkeys on YubiKey NEO Smartcard](https://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/).
Refer to this blog post for better motivations for the instructions.

Pre-requisites
--------------

You need the following before moving on:

 -  Two Yubikey 4 keys, can be ordered from [Yubico](https://www.yubico.com).
 -  One computer guaranteed to not connect to any network, i.e. wifi hardware
    non-existent or disabled, network cables unconnected etc. It is an
    advantage if the computer does not have a harddisk.
 -  ISO image to boot on the air-gap computer, see [air-gap howto](airgap.md)
    for instructions how to make one.
 -  One computer with network connection.
 -  One, or preferably three, USB memory sticks. I used normal sized SD card to
    get a write protection switch, which is not secure enough to be a security
    feature but can still save you from awful mistakes.
    One or two USB memories is used for storing the private keys, and one is
    used to transfer public key to an unsafe computer, and will not be needed
    anymore once this is done.

All instructions below is done on the air-gap computer.

Mounting USB memory
-------------------

After inserting the USB memory, use `dmesg` command to determine device. Then
mount the device. Example below assumes the device is /dev/sda1:

    sudo mount /dev/sda1 /mnt

The directory `mnt` will be called `<path to USB>`.

Since USB device normally use FAT file system for maximum portability, it does
not have all the Unix ownerships. One practical consequence of this is that the
mount point will require root privilege, since the disk was mounted by root.
And this cannot be changed using `chown`.

This can be circumvented by adding an entry in the fstab to allow user to
mount, but I was too lazy to do this.

Setup gpg.conf
--------------

For better choice of cryptographic algorithms and get smart card support, the
.gnupg directory is created and the gpg.conf file modified.

```
mkdir ~/.gnupg
chmod 700 ~/.gnupg
cat > gpg.conf <<EOF
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAMELLIA256 CAMELLIA192 CAMELLIA128 TWOFISH
cert-digest-algo SHA512
use-agent
EOF
chmod 600 ~/.gnupg/gpg.conf
```

Generate master key
-------------------

The master key is the key that you are not supposed to use in the wild, and
the key you really want to keep safe. If you have to revoke a sub-key, this is
not a catastrophe. But loosing master key means you have to rebuild your
credibility from the start again.

The master key will be used for signing other keys, your own as well as others.
This requires certify ability, and only the master key can have that ability.
But the master key will also have sign ability, which is useful when signing
key transition documents.

If you are paranoid, you should choose an expiration period. This is useful in
the case where you loose both your master key and the revokation certificate
for it. Personally, I choose no expiration period, since I feel I have it
safe enough.

```
$ gpg --gen-key
gpg (GnuPG) 1.4.16; Copyright (C) 2013 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 4
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 
Key does not expire at all
Is this correct? (y/N) y

You need a user ID to identify your key; the software constructs the user ID
from the Real Name, Comment and Email Address in this form:
    "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"

Real name: Mats Liljegren
Email address: mats.liljegren@enea.com
Comment: Work
You selected this USER-ID:
    "Mats Liljegren (Work) <mats.liljegren@enea.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
You need a Passphrase to protect your secret key.

gpg: gpg-agent is not available in this session
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.

gpg: /home/mlil/.gnupg/trustdb.gpg: trustdb created
gpg: key 64CBE032 marked as ultimately trusted
public and secret key created and signed.

gpg: checking the trustdb
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
pub   4096R/64CBE032 2016-02-25
      Key fingerprint = C160 57BB B94F 45E1 6429  4DFA 87DA 6642 64CB E032
uid                  Mats Liljegren (Work) <mats.liljegren@enea.com>

Note that this key cannot be used for encryption.  You may want to use
the command "--edit-key" to generate a subkey for this purpose.
```

Key ID
------

You need to know your key ID. To figure it out, start by listing all your
current public keys, which currently should be only one:

    gpg --list-keys
    /home/mlil/.gnupg/pubring.gpg
    -----------------------------
    pub   4096R/64CBE032 2016-02-25
    uid                  Mats Liljegren (Work) <mats.liljegren@enea.com>

The syntax of the line of our interest is:

    pub   <key size bits><algorithm letter>/<key ID> <creation date>

In my key created above, I have a 4096 bits RSA key, which is written 4096R.
The line becomes:

    pub   4096R/64CBE032 2016-02-25

The key ID part is then 64CBE032. Looking at the fingerprint, we can see that
this is actually the last part of the fingerprint:

    gpg --fingerprint
    /home/mlil/.gnupg/pubring.gpg
    -----------------------------
    pub   4096R/64CBE032 2016-02-25
          Key fingerprint = C160 57BB B94F 45E1 6429  4DFA 87DA 6642 64CB E032
    uid                  Mats Liljegren (Work) <mats.liljegren@enea.com>

Add user ID
-----------

You can add photo and names. The photo should be small in size, I would
recommend aroud 6kB, and in JPEG format. Note that photos are of more use
for people you know rather than for unknown people, or for people to remember
who you are.

First, edit the key to add user IDs:

    gpg --edit-key <key ID>

which in our case becomes:

    gpg --edit-key 64CBE032

To add a photo, use command "addphoto". To add a user ID, use command
"adduid".

Remember to finish by using the command "save", or else your changes will be
lost.

Create revocation certificate
-----------------------------

In case your master key gets compromised, you can generate a revocation
certificate now, and use it when needed. The command syntax is:

    gpg --output <file> --gen-revoke <key ID>

Since the use case for using this specific revocation certificate is a
compromised key, this should be reflected when answering the questions.

To create a printable file of the revocation certificate, use:

    paperkey --secret-key <certificate file> --output <output file>

Where the "certificate file" is the file given as output file when the
certificate was generated. The "output file" should be a file to be
created and should reside in the USB memory.

The safest, although not completely safe, way of printing this would be to
unplug the printer from the network and insert the USB memory into it, letting
the printer print directly from the USB memory. Not all printers supports this.

Create subkeys
--------------

Since Yubikey 4 supports 4096 bits key size, I opt to use that in this
example. More bits takes more time to encrypt, but with todays computers
this should not be a problem.

It seen as good practice to have separate keys for different purposes, i.e.
only have one key for signing, another for encrypting/decrypting, yet another
for authentication and a separate one for certify.

The master key is the only key that can certify, which means that we will have
three additional sub-keys to create: sign, encrypt and authenticate. This is
also the number of key slots available in the Yubikey.

Starting with the sign sub-key:

```
$ gpg2 --expert --edit-key 64CBE032
gpg (GnuPG) 2.0.22; Copyright (C) 2013 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Secret key is available.

pub  4096R/64CBE032  created: 2016-02-25  expires: never       usage: SC  
                     trust: ultimate      validity: ultimate
[ultimate] (1). Mats Liljegren (Work) <mats.liljegren@enea.com>

gpg> addkey
Key is protected.

You need a passphrase to unlock the secret key for
user: "Mats Liljegren (Work) <mats.liljegren@enea.com>"
4096-bit RSA key, ID 64CBE032, created 2016-02-25

Please select what kind of key you want:
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
Your selection? 4
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 1y
Key expires at lör 25 feb 2017 08:20:57 CET
Is this correct? (y/N) y
Really create? (y/N) y
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.

pub  4096R/64CBE032  created: 2016-02-25  expires: never       usage: SC  
                     trust: ultimate      validity: ultimate
sub  4096R/8C41E725  created: 2016-02-26  expires: 2017-02-25  usage: S   
[ultimate] (1). Mats Liljegren (Work) <mats.liljegren@enea.com>
```

Next is the encryption key:

```
gpg> addkey
Key is protected.

You need a passphrase to unlock the secret key for
user: "Mats Liljegren (Work) <mats.liljegren@enea.com>"
4096-bit RSA key, ID 64CBE032, created 2016-02-25

Please select what kind of key you want:
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
Your selection? 6
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 1y
Key expires at lör 25 feb 2017 08:22:05 CET
Is this correct? (y/N) y
Really create? (y/N) y
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.

pub  4096R/64CBE032  created: 2016-02-25  expires: never       usage: SC  
                     trust: ultimate      validity: ultimate
sub  4096R/8C41E725  created: 2016-02-26  expires: 2017-02-25  usage: S   
sub  4096R/6ADDA02B  created: 2016-02-26  expires: 2017-02-25  usage: E   
[ultimate] (1). Mats Liljegren (Work) <mats.liljegren@enea.com>
```

And lastly, the authentication key:

```
gpg> addkey
Key is protected.

You need a passphrase to unlock the secret key for
user: "Mats Liljegren (Work) <mats.liljegren@enea.com>"
4096-bit RSA key, ID 64CBE032, created 2016-02-25

Please select what kind of key you want:
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
Your selection? 8

Possible actions for a RSA key: Sign Encrypt Authenticate 
Current allowed actions: Sign Encrypt 

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? s

Possible actions for a RSA key: Sign Encrypt Authenticate 
Current allowed actions: Encrypt 

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? e

Possible actions for a RSA key: Sign Encrypt Authenticate 
Current allowed actions: 

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? a

Possible actions for a RSA key: Sign Encrypt Authenticate 
Current allowed actions: Authenticate 

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? q
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 1y
Key expires at lör 25 feb 2017 08:23:01 CET
Is this correct? (y/N) y
Really create? (y/N) y
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.

pub  4096R/64CBE032  created: 2016-02-25  expires: never       usage: SC  
                     trust: ultimate      validity: ultimate
sub  4096R/8C41E725  created: 2016-02-26  expires: 2017-02-25  usage: S   
sub  4096R/6ADDA02B  created: 2016-02-26  expires: 2017-02-25  usage: E   
sub  4096R/35EC04FC  created: 2016-02-26  expires: 2017-02-25  usage: A   
[ultimate] (1). Mats Liljegren (Work) <mats.liljegren@enea.com>
```

Remember to save the keys:

```
gpg> save
```
Backing up the keys
-------------------

The next step is to move the keys to the smart card. Note that move implies
delete the source. Smart card implies no possibility to read the key, only
use it. So this is a good time to backup the keys so you can create new smart
card keys in the future.

Backup the master secret key:

    gpg2 --armor --export-secret-keys <key ID> | sudo tee <path to USB>/masterkey.asc > /dev/null

Backup the sub-keys belonging to the master key:

    gpg2 --armor --export-secret-subkeys <key ID> | sudo tee <path to USB>/subkeys.asc > /dev/null

While at it, also backup the public key so we can send this to servers:

    gpg2 --armor --export-keys <key ID> | sudo tee <path to USB>/publickey.asc > /dev/null

Also backup the whole .gnupg directory:

    chown -R root ~/.gnupg
    cp -a ~/.gnupg <path to USB>/gnupg
    chown -R $USER ~/.gnupg

This will be useful in the future when running scripts and don't want to use
the Yubikey. When I signed 200+ user IDs I was thankful of not having to enter
the YUbikey pin code each time. The GPG passphrase can be cached, which might
be ok running on the air-gap computer, but I do not want Yubikey pin code
caching.

If you have more USB memory sticks for storing private keys, you need to
mount that one as well (optionally unmounting the current one), and repeat
the steps above. Just make sure you have one memory stick available for
transferring your public key.

Configure smart card
--------------------

Insert your Yubikey 4 smart card, and use follow command to start configuration
session:

    gpg2 --card-edit

First of all, enter admin mode:

    admin

First of all, change pin codes, both the pin for daily use as well as the
management pin code:

    passwd

Yubikey default pin code is 123456 and the default admin pin code is 12345678.

Next, change your `name`, `lang` (optional), `url` where the public key can be
fetched, `sex` and `login` user name. All these are optional, although I
strongly recommend to update at least name. The `url` is quite handy since
GPG can use this to fetch your key when using the Yubikey in a new computer.
But there are other ways of doing it too.

Move secret keys to Yubikey
---------------------------

WARNING: Be sure you have done a proper backup of your keys, especially the
secret keys since they will be deleted from the keyring!

Edit the key:

    gpg2 --edit-key <key ID>

Toggle from public keys to secret keys:

    toggle

Select first key, which should be our sign key and move it:

    key 1
    keytocard

Choose signature key slot.

Unselect key 1, select key 2, and move that encryption key:

    key 1
    key 2
    keytocard

Choose encryption key slot.

Unselect key 2, select key 1, and move that authentication key:

    key 2
    key 3
    keytocard
Choose authentication key slot.

Save your changes:

    save

You may repeat the backup step here if you wish, but be sure not to overwrite
the previous backup or else your Yubikey will be the only place where you have
your secret keys.

Copy public key to a new USB memory
-----------------------------------

Mount a new USB memory for transferring your public key to an unsafe computer.
Then copy the public key to that USB memory:

     
    gpg2 --armor --export-keys <key ID> | sudo tee <path to USB>/publickey.asc > /dev/null

Unmount
-------

We are now finished with the key generation. Make sure you unmount the USB
memories before turning off the power to the air-gap computer.

Upload public key
=================

On any computer with Internet connection, insert the USB memory that only
contains the public key. This key needs to first be imported, since GPG always
work with its keyring, and then sent to an SKS server.

    gpg --import <path to public key>
    gpg --keyserver pool.sks-keyservers.net --send-keys <key ID>

The last command can be repeated since it will allocate a random server to send
to from a pool of servers, and you might get a non-cooperating server. You can
also check the following web page to get current status of the servers:

    https://sks-keyservers.net/status

Licese
======

![License icon](license-icon-88x31.png)
This work is licensed under a Creative Commons Attribution 4.0 International License.


