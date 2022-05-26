# passF

passF is a password manager based on [pass](https://www.passwordstore.org). You can see this app as a mobile client of [pass](https://www.passwordstore.org).


<p align="center">
<a href='https://play.google.com/store/apps/details?id=xyz.delaosa.passf&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img alt='Get it on Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png'/></a>
</p>



# Features

- Clone an existing pass repository (SSH)
- Create/View/Edit/Delete password entries
- Browse pass repository hierarchically or flat
- Search
- Generation of SSH and PGP keys
- Git pull and push
- Secure storage
- Biometric access

# Howto

In case you are reusing some exiting SSH/PGP keys just import them into the settings section of passF.

It's recommended to generate a new set of SSH and PGP keys for passF, you can do it with passF or anywhere else and import them in.

From passF:

- Go to Setting -> Repository/Git
- Fill Git URL
- Click 'Generate keys' from taskbar menu
- Click on 'Copy public key to clipboard' and keep it somewhere for later use.
- Click on save icon

- Go to Setting -> PGP/Keys
- Click 'Generate keys' from taskbar menu
- Click on Private Key share icon, write down backup passphrase and keep it somewhere safe for later use. Select destination for the exported key.
- Click on save icon


From a computer:

In case you have generated new keys:

1. Add previously copied public SSH key to the list of authorized keys in your git repository.

2. In a computer with a copy of the pass repository, import previously exported private PGP key. In order to decrypt the file, backup passphrase will we asked firstly and secondly PGP private key passphrase.
```
# gpg --decrypt pgp_private.asc.sec | gpg  --import 
  gpg: key 14BE218163D45487: "passF <passf@delaosa.xyz>" not changed
  gpg: key 14BE218163D45487: secret key imported
  gpg: Total number processed: 1
  gpg:              unchanged: 1
  gpg:       secret keys read: 1
  gpg:   secret keys imported: 1

```

3. Trust the new key:
```
# gpg --edit-key  passf@delaosa.xyz
  gpg (GnuPG) 2.2.20; Copyright (C) 2020 Free Software Foundation, Inc.
  This is free software: you are free to change and redistribute it.
  There is NO WARRANTY, to the extent permitted by law.
  
  Secret key is available.
  
  sec  rsa2048/14BE218163D45487
       created: 2020-07-02  expires: never       usage: SC  
       trust: unknown       validity: unknown
  ssb  rsa2048/F929D2C70F3EBECE
       created: 2020-07-02  expires: never       usage: E   
  [ unknown] (1). passF <passf@delaosa.xyz>
  
  gpg> trust
  sec  rsa2048/14BE218163D45487
       created: 2020-07-02  expires: never       usage: SC  
       trust: unknown       validity: unknown
  ssb  rsa2048/F929D2C70F3EBECE
       created: 2020-07-02  expires: never       usage: E   
  [ unknown] (1). passF <passf@delaosa.xyz>
  
  Please decide how far you trust this user to correctly verify other users' keys
  (by looking at passports, checking fingerprints from different sources, etc.)
  
    1 = I don't know or won't say
    2 = I do NOT trust
    3 = I trust marginally
    4 = I trust fully
    5 = I trust ultimately
    m = back to the main menu
  
  Your decision? 5
  Do you really want to set this key to ultimate trust? (y/N) y
  
  sec  rsa2048/14BE218163D45487
       created: 2020-07-02  expires: never       usage: SC  
       trust: ultimate      validity: unknown
  ssb  rsa2048/F929D2C70F3EBECE
       created: 2020-07-02  expires: never       usage: E   
  [ unknown] (1). passF <passf@delaosa.xyz>
  Please note that the shown key validity is not necessarily correct
  unless you restart the program.

gpg> quit
```

4. Add the new PGP key to the pass repository, don't forget to include keys formerly in use by pass(usually in ~/.password-store/.gpg-id).

```
pass init former@key.user passf@delaosa.xyz
```  

5. Push new changes

```
pass git push
```  


Back to passF:

From the main screen pull down to refresh and pass repository will be cloned from your remote git repository.