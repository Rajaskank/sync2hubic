#!/bin/bash

# Date
DATE=`date +%d-%m-%Y`

# URL d'authentification à Hubic
URL="https://domaine.tld/auth/v1.0/"
# User défini par hubic2swiftgate
USER="hubic"
# Mot de passe du compte hubiC
KEY="PASSWORD"
# Conteneur sur hubiC
BKCONT="HubiC-DeskBackup_BACKUP"

# Répertoires local
BACKUPDIR="/backups"
TEMPDIR=$BACKUPDIR/$DATE
# Répertoire à backuper
BKLOC=$BACKUPDIR/archives

# Archive
ARCHIVE=$BKLOC/$DATE.tar.xz

# RSync
OPTS="-ah --force --ignore-errors"

# Log
LOGDIR="/var/log"
LOG=$LOGDIR/s2h_$DATE.log

echo " -> Début du backup" > $LOG
echo " -> Vérification des dossiers..."
if [ -d $BACKUPDIR ];
then
        echo " -> ${BACKUPDIR} existe !";
else
        echo " -> Création de ${BACKUPDIR}..."
        mkdir $BACKUPDIR;
fi
if [ -d $TEMPDIR ];
then
        echo " -> ${TEMPDIR} existe, suppression...";
        rm -rf $TEMPDIR
        echo " -> Création de ${TEMPDIR}..."
        mkdir $TEMPDIR;
else
        echo " -> Création de ${TEMPDIR}..."
        mkdir $TEMPDIR;
fi
if [ -d $BKLOC ];
then
        echo " -> ${BKLOC} existe !";
else
        echo " -> Création de ${BKLOC}..."
        mkdir $BKLOC;
fi

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

echo " -> Création de l'archive ${ARCHIVE}..."
tar --warning=none -Jcf $ARCHIVE --directory=$BACKUPDIR $DATE
echo " -> Suppression des fichiers temporaires..."
rm -rf $TEMPDIR
# Suppression des archives de plus de 7 jours
cd $BKLOC
DEL=$(find -type f -mtime +6 -printf "%P ")
if test -z "$DEL"
then
  echo " -> Pas d'archive de plus de 7 jours..." >> $LOG
else
  echo " -> Suppression des archives de plus de 7 jours sur hubiC..." >> $LOG
  export ST_AUTH=$URL
  export ST_USER=$USER
  export ST_KEY=$KEY
  swift -v delete $BKCONT $DEL >> $LOG
  echo " -> Suppression des archives de plus de 7 jours en local..." >> $LOG
  rm -vf $DEL >> $LOG
fi
echo " -> Transfert en cours..."
# Date de début
DDEB=`date +%d-%m-%Y`
HDEB=`date +%H:%M:%S`
echo " -> Début du transfert à ${HDEB} le ${DDEB}," >> $LOG
echo " -> Pour le dossier ${BKLOC} dans le conteneur ${BKCONT}." >> $LOG
echo " - Archive sur hubiC:" >> $LOG
# Calcul du temps
temps() { t=$(($2-$1)) ; printf " -> Fin du backup à ${HFIN} le ${DFIN} en %02dh %02dm %02ds\n" $(($t/3600)) $((($t%3600)/60)) $(($t%60)) ; }
t1=$(date +%s)
cd $BKLOC
export ST_AUTH=$URL
export ST_USER=$USER
export ST_KEY=$KEY
swift -v upload -c $BKCONT * >> $LOG
t2=$(date +%s)
# Date de fin
DFIN=`date +%d-%m-%Y`
HFIN=`date +%H:%M:%S`
temps t1 t2  >> $LOG
echo " -> Suppression des fichiers temporaires..."
rm -rf $TEMPDIR
echo " -> Suppression des logs de plus de 7 jours..."
find $LOGDIR -mtime +6 -exec rm -vf {} \;
echo " -> Done, goodbye !"
echo "" >> $LOG
cat $LOG
exit 0
