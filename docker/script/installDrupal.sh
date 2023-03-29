#!/bin/bash

# From the projet root execute scripts_local/install.sh, if you want to install a new DB add the parameter new
# otherwise the script will execute only the drush functions
#source .env
start_time=$(date +%s)
elapsedBD=0

echo "**** Start install project CGS *****"

if [ ! -f /var/www/html/web/sites/default/settings.php ]; then
    echo "Setting config"
    cp /var/www/html/docker/config/settings.php /var/www/html/web/sites/default/settings.php
    cp /var/www/html/docker/config/services.yml /var/www/html/web/sites/default/services.yml
fi

mysqlCommand="mysql -u root -h database"
#echo "- backup GCS BD"
#mysqldump -u root -h database --databases $DATABASE_NAME --default-character-set=utf8 > /var/www/html/docker/dump/backup-$today.sql
#gzip /var/www/html/docker/dump/backup-$today.sql
echo "- drop database if exists $DATABASE_NAME"
$mysqlCommand -e "drop database if exists $DATABASE_NAME"
echo "- create database $DATABASE_NAME"
$mysqlCommand -e "create database $DATABASE_NAME"
cat /var/www/html/docker/dump/backup.sql.gz | gunzip -c - | $mysqlCommand $DATABASE_NAME
end_time=$(date +%s)
elapsedBD=$(( end_time - start_time ))

cd /var/www/html
#echo "Composer install"
composer install --optimize-autoloader

echo "Execute drush functions"
echo "drush updb --no-post-updates -y"
drush updb --no-post-updates -y
drush cr
echo "drush cim -y"
drush cim -y
echo "drush updb -y"
drush updb -y
drush cr
#echo "drush vdm-account:add-test-users -y --env=local"
#drush vdm-account:add-test-users -y --env=local


echo "==== Script end ====="
end_time=$(date +%s)
elapsed=$(( end_time - start_time ))
echo "Time to install BD: $((elapsedBD/3600))h $(((elapsedBD/60)%60))m $((elapsedBD%60))s"
echo "Time to build: $((elapsed/3600))h $(((elapsed/60)%60))m $((elapsed%60))s"
