Sync2Mega
===========
Synchronize your files automatically to Mega.

Requirements
------------

* Linux
* RSync
* Swift
* Hubic2swiftgate https://github.com/oderwat/hubic2swiftgate
* HubiC account

Installation
------------

```
apt-get install rsync swift
```

Configuration
------------

Auth

```
# URL d'authentification à Hubic
URL="https://domaine.tld/auth/v1.0/"
# User défini par hubic2swiftgate
USER="hubic"
# Mot de passe du compte hubiC
KEY="PASSWORD"
```

Contener

```
# Conteneur sur hubiC
BKCONT="HubiC-DeskBackup_BACKUP"
```

Edit DATA and SQL as needed:

```
# DATA
echo "-> Backup data in ${TEMPDIR}..."
mkdir $TEMPDIR/apache2
rsync $OPTS /etc/apache2/sites-available $TEMPDIR/apache2
rsync $OPTS /var/www $TEMPDIR
# END DATA
# SQL
echo "-> Dump SQL databases in ${TEMPDIR}..."
mkdir $TEMPDIR/mysql
mysqldump -u<SQL user> -p<SQL password> <SQL base> | gzip >$TEMPDIR/mysql/<SQL base>.gz
#END SQL
```

Create a new entry to your crontab file:

```
crontab -e
```

And paste (every day at 6h):

```
0 6 * * * /path/to/sync2mega.sh
```

Thanks.
