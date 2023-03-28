#!/bin/bash

# From the projet root execute scripts_local/install.sh, if you want to install a new DB add the parameter new
# otherwise the script will execute only the drush functions
#source .env

echo "**** Start install BD Kaiacode *****"

start_time=$(date +%s)
elapsedBD=0
BD=$1
mysqlCommand="mysql -u root -h database"
found=FALSE
today=$(date +%Y-%m-%d_%Hh%Mm%Ss)

if [ -f "/var/www/html/dump/$BD" ]; then
    found=TRUE
    BD="/var/www/html/dump/$BD"
  else
    if cd /var/www/html/dump; then
        lastelement=$(ls *.sql.gz | tail -1)
        found=TRUE
        BD="/var/www/html/dump/$lastelement"
        else
          echo "No backup BD found"
          exit
    fi
fi
if [[ $found = "TRUE" ]]; then
  #echo "- backup database"
  #mysqldump -u root -h database --databases $DATABASE_NAME --default-character-set=utf8 >/var/www/html/dump/backup-$today.sql
  #gzip /var/www/html/dump/backup-$today.sql
  echo "- drop database if exists $DATABASE_NAME"
  $mysqlCommand -e "drop database if exists $DATABASE_NAME"
  echo "- create database $DATABASE_NAME"
  $mysqlCommand -e "create database $DATABASE_NAME"
  echo "- import $BD"
  cat $BD | gunzip -c - | $mysqlCommand $DATABASE_NAME
fi
echo "*** end fonction ***"
end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "Time to install BD: $((elapsed / 3600))h $(((elapsed / 60) % 60))m $((elapsed % 60))s"
