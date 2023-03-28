#!/bin/bash

# From the projet root execute scripts_local/install.sh, if you want to install a new DB add the parameter new
# otherwise the script will execute only the drush functions
#source .env

echo "**** Start backup BD Kaiacode *****"

start_time=$(date +%s)
elapsedBD=0
BD=$1
mysqlCommand="mysql -u root -h database"
today=$(date +%Y-%m-%d_%Hh%Mm%Ss)

mkdir -p /var/www/html/dump
echo "- backup database"
mysqldump -u root -h database --databases $DATABASE_NAME --default-character-set=utf8 >/var/www/html/dump/backup-$today.sql
gzip /var/www/html/dump/backup-$today.sql
echo "*** end fonction ***"
end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "Time to install BD: $((elapsed / 3600))h $(((elapsed / 60) % 60))m $((elapsed % 60))s"
