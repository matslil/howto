% GPG Howto
% Mats Liljegren

About this howto
================

I decided I wanted GPG keys, and I wanted to do it the "proper" way. After
extensive searches around the net and a lot of own trials, I gained some
knowledge that I now want to share with this howto.

There are a lot of howto's in the net, but every howto had things I thought
was important but was missing. So that is wy I wrote this howto. It most
likely has things missing too, especially if doing things different from how
I have done.

Source code for this howto can be found here:

<https://github.com/matslil/howto>

Quick GPG into
==============

The following web site explains what GPG is:

<https://en.wikipedia.org/wiki/GNU_Privacy_Guard>

This is the official GPG web site:

<https://www.gnupg.org>

This is the standard for using GPG with mails:

<https://tools.ietf.org/html/rfc4880>

This is a somewhat more userfriendly explanation about GPG, with Ubuntu
focus:

<https://help.ubuntu.com/community/GnuPrivacyGuardHowto>

The man-page is also a good source of information. I always use "gpg2",
since it has better support for smart cards.

Some things were not that obvious to me from the beginning, so I'll try to
cover them in this chapter. First a nice graph below how things relate to
each other:

![GPG diagram](gpg-overview)

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
 2. Backup copy of private key data is stored safely, e.g. in a safe. This
    copy is never seen by any unsafe (i.e. non-airgap) computer.
 3. For usage, private key data is stored on a Yubikey, making copying
    impossible.

These instructions have been greatly influenced by Simon Josefsson's blog
[Offline GnuPG Master Key and Subkeys on YubiKey NEO Smartcard](https://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/).
Refer to this blog post for better motivations for the instructions.

Creating GPG signature policy
-----------------------------

If you want to you can have web page describing what you mean with signing
a GPG key. It should contain the following information:

 -  Hash of the public key(s) it covers.
 -  Where this key can be found, e.g. at pools.sks-keyservers.net, and/or
    at an URL.
 -  What does the signature levels mean to you? What kind of checks have you
    made for each level?
 -  When might you revoke your signature? E.g. if the signed key does not sign
    your key?

You should also be prepared that you might change your mind after having signed
a number of keys based on your policy, and then change the policy. I suggest to
use dates to say "This is the policy for signatures done starting from this
date". People can then know what a signature meant at the time it was done.

Here is my policy that you can use as a template if you wish, just be sure you
remove any information about me first:

<https://sites.google.com/site/matsgliljegrenpersonalpage/files/gpg-signature-policy.md>

As you can see I use sites.google.com to have my personal free home page.

Pre-requisites
--------------

You need the following before moving on:

 -  Two Yubikey 4 keys, can be ordered from [Yubico](https://www.yubico.com).
 -  One computer guaranteed to not connect to any network, i.e. wifi hardware
    non-existent or disabled, network cables unconnected etc. It is an
    advantage if the computer does not have a harddisk.
 -  ISO image to boot on the air-gap computer, see air-gap howto.
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

Using the keys
==============

This chapter will describe how to use the Yubikey.

Make GPG see the key
--------------------

When using a new machine where you have never before used your key you need to
first download your public key and then created stubs for the secret part so
they refer to your Yubikey.

First, insert your Yubikey.

If you have an Internet connection you can download your key from the SKS
keyserver pool:

    gpg --keyserver pool.sks-keyservers.net --recv-keys <key ID>
    gpg --card-status

The "--card-status" will create the secret key stubs referring to your
Yubikey.

If you don't have Internet connection, or do not remember your key ID, but
have the key available using an URL and this URL has been configured into
your key, you can download it. Insert your Yubikey, and use the following
command:

    gpg2 --card-edit fetch

This should take care of the stubs as well. At this stage, you might want to
download the key anyway from the keyservers in case there are new important
signatures you want included.

Using claws-mail
----------------

Claws-mail is what I use the most, so it was the first one I got working with
GPG encryption/decryption. It needs three plugins to work:

 -  PGP/Core
 -  PGP/inline
 -  PGP/MIME

On an Ubuntu system, this is done by:

    sudo apt-get install claws-mail-pgpinline claws-mail-pgpmime

Using Outlook
-------------

I got this working using Outlook 2013 on Windows 7. However, Outlook became
instable and turned the needed plugin off for me. Newer versions of Outlook
might work better.

 1. Install gpg4win <https://www.gpg4win.org>

 2. Start Kleopatra

 3. Choose 'Lookup certificates on server'

 4. Enter your name, e-mail address or key ID to search for your key.

 5. Click on the entry showing your key.

 6. Click 'import'.

 7. Insert your Yubikey

 8. Invoke a shell and run:

        gpg --card-status

Using Android phone
-------------------

You can decrypt mail handled by gmail application on your Android phone, if
you have NFC. If so, install the following app from Google Play Store:

 -  OpenKeychain: Easy PGP, by Sufficiently Secure

When starting the app you first need to tell it what your key ID is, and then
hold the Yubikey to associate the key ID with your Yubikey. A mistake I did
was to remove the Yubikey as soon as it reacted to it. Make sure it says that
it is finished reading your Yubikey before removing it!

Participating in a key signing party
------------------------------------

To make your key trustworthy, you need to get signatures on your user IDs.
The trustness is, somewhat simplified, calculated based on how many key
signatures away from a key you have indicated as trustworthy. The result
is seen as "valid" level.

One way to get a number of signatures to improve your key's trustness is
to participate in a key signing party. This is basically a get together
where you check other peoples identities, their key fingerprint and their
user IDs. You then download their keys, sign them, and then send an
encrypted mail to them with their signed key.

### Preparing for participating on a key signing party

Before going to a key signing party, you usually have to prepare by doing the
following things:

 1. Upload your key either by e-mail to the organizer, to a special keyserver
    or to a SKS keyserver. Which way to do this should have been stated in the
    event invitation.

 2. When everybody are expected to have uploaded their keys, download the list
    of keys. This should be a text file where each entry should look like the
    output of `gpg --fingerprint` command, but probably without information
    about sub-keys.

 3. Print this file on paper, so you don't need to hold a computer when doing
    ID checking.

 4. On the printed list of keys, enter calculated hashes per organizers
    instructions.

 5. If you're ambititous you also print all pictures stored in the public keys.

 6. Make a badge you can wear at the party stating:
     -   Entry number as stated in the printed key list, so people can quickly
         find you in the list. This is the most important information, so make
         it clearly visible.
     -   Statement that you have checked key fingerprint. Make sure that this
         is true as well.

If you're ambitious you might want to read up on
<http://www.consilium.europa.eu/prado/en/check-document-numbers.html> for
information about how to verify European ID documentation.

### At the key signing party

The hashes for the file should be announced verbally, to avoid problems with
some joker switching papers or something. Check that the announced hash
matches what you have noted. If not, leave the party. Hope for better luck
the next time. But make sure the mismatch isn't because of mispronounciation.

Note that sometimes people try fake documents just to see how hard it can be
to fool people. So if you're not convinced by some presented documentation,
don't be afraid to say so. The document might be valid, but you must still be
convinced, and sometimes the present documentation might be of some type that
you're not familiar with.

Make sure you have your badge clearly visible when the event starts.

Some events can take hours to complete. If you feel that your're too tired to
do a decent ID check, it is ok to leave. You still have some signatures,
better than nothing, and better than signing people you don't really have a
clue who they are.

If you intend to check the validity of the document number, make sure you
note them on the printed key list paper.

### After the key signing party

When the party is over, make sure there is a forum where all participants can
share any findings about faked IDs. Experience has showned that individuals
are not great at finding them all, but at bigger events someone usually spots
the fake and might not have the guts to shout it out, afraid of falsely
accusing someone.

It can therefore be a good idea to discuss this on a mailing list. If several
people has found the same ID being fake, then it is probably fake. Something
that is good for the rest to know.

For European documents you might want to check the validity of the
document number at
<http://www.consilium.europa.eu/prado/en/check-document-numbers.html>.

Make a copy of the file with list of keys you printed earlier, and remove all
keys that you have decided not to sign. Then for each entry, you need to sign
the key. This needs to be done in such a way that you can send an encrypted
mail for each user ID, and thereby check the validity of the e-mail address.
If the receiver can decrypt the signed key, the e-mail was probably owned by
this person and he therefore deserved your signature.

Unfortunately GPG is somewhat hard to work with, doing the above requires
a number of steps:

 1. Download the public key you're about to sign.
 2. Sign it, optionally supplying a policy URL.
 3. Export the signed key to a file.
 4. Delete all user identities except for one. Don't count any
    photos or revokes identities.
 5. Export the key again to a new file.
 6. If there are more user IDs to handle, re-import the original signed key
    file, and start over at step 4.
 7. For each file with only one signed user ID, make an e-mail with the
    key as an attachment, and encrypt this mail.
 8. Send the mail to the user ID signed in the attachment file.
 9. Start over at step 1 for next public key you are about to sign.

The reason for doing things this way is to ensure that the e-mail addresses
given are valid addresses and useable by the key owner. Note that not
everyone want you to upload your signatures to a public SKS keyserver.

When I needed to do this for about 150 public keys, I ended up writing a
script. If you want how to perform above step, read my scripts at:

<https://github.com/matslil/keysign>

There are other tools as well:

 -  caff - <https://wiki.debian.org/caff>
 -  pius - <https://www.phildev.net/pius>

I didn't use them since I want to know what is happening, and I couldn't
understand their source code well enough to feel comfortable. I tried to
make my script simple enough that you should be able to understand what
it does.

Tell people about your key
--------------------------

The shortest way of telling people you have a GPG key, is by simply saying:

GPG fingerprint: <fingerprint>

This makes it possible for people to search for your key based on the key
fingerprint by using last part as key ID and then verify the fingerprint when
a match was found. This line could be added to your business card and e-mail
signature.

Troubleshooting
===============

I had some problems with smart card support and GPG. In the end, it boiled
down to two issues:

 -  Multiple smart card readers
 -  Multiple smart cards for same key ID

Multiple smart card readers cause problems
------------------------------------------

GPG will by default take the first smart card reader it finds and use it.
It does not have intelligence like if the first reader does not have any
smart card inserted, try next. It will fail instead, complaining there was
no smart card.

To check what smart card readers GPG can see, use the following command:

    pcsc_scan

To force usage of a reader not being first in that list, create a file named
`~/scdaemon.conf`, and add a line with the following syntax:

    reader-port <name>

The "name" part can be copied from the output of the `pcsc_scan` output.

Kill scdaemon and gpg-agent daemons to make sure the change is noticed:

    killall scdaemon
    killall gpg-agent

These will automatically start again next time you use GPG. Test this with:

    gpg2 --card-status

Problems with multiple smart cards for same key ID
--------------------------------------------------

The secret key stores a reference which smart card to use. When doing
`gpg2 --card-status` to update this, all keys will be updated. This includes
master key as well as sub-keys.

I have one Yubikey for my master key and one Yubikey for all my sub-keys.
When I have used one of them, I can't use the other. The simplest way to
switch is to delete the private keys. Since they are only stubs, you do not
loose valuable information.

    gpg2 --list-secret-keys

This will list all secret keys, to make sure you select the right key.

    gpg2 --delete-secret-key <key ID>

Use the master key ID to delete all secret keys. Then insert the Yubikey you
want to associate the key with and run:

    gpg2 --card-status

This will re-create the stubs again, referring to your new Yubikey.

License
=======

![](license-icon-88x31.png)

Copyright (C) 2016, Mats G. Liljegren

This work is licensed under a Creative Commons Attribution 4.0 International License.

