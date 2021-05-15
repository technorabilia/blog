#!/bin/bash

echo +++ Start...
. ./.env
cd /volume1/docker/blog

echo +++ Docker-compose...
docker-compose start

echo +++ Creating blog database backup...
docker-compose run --rm wordpress-cli wp db export --default-character-set=utf8mb4 blog_db.sql

echo +++ Docker-compose...
docker-compose stop

ARCHIVE=/volume1/backup/blog/blog_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz
echo +++ Creating blog archive to $(basename $ARCHIVE)
tar -czf $ARCHIVE html mysql

echo +++ Deleting sql backup...
rm html/blog_db.sql

echo +++ Docker-compose...
docker-compose down

echo +++ Deleting html mysql directories...
rm -rf html mysql

echo +++ Creating html mysql directories...
mkdir html mysql

echo +++ Docker-compose...
docker-compose up -d

echo +++ Sleeping...
sleep 30

echo +++ Docker-compose...
docker-compose stop

echo +++ Creating backup wp-config.php...
mv html/wp-config.php .

echo +++ Deleting html directory...
rm -rf html

echo +++ Creating html directory...
mkdir html

ARCHIVE=/volume1/backup/$DOMAIN/$(ls /volume1/backup/$DOMAIN | tail -n 1)
echo +++ Restoring blog from archive $(basename $ARCHIVE)
tar -xzf $ARCHIVE -C html

echo +++ Restoring backup wp-config.php...
mv wp-config.php html/.

echo +++ Change ownership html directory...
chown -R 33:33 html

echo +++ Docker-compose...
docker-compose start

echo +++ Sleeping...
sleep 30

echo +++ Restoring blog database backup...
docker-compose run --rm wordpress-cli wp db import --default-character-set=utf8mb4 APP-DATA.SQL

echo +++ Deleting sql backup...
rm html/APP-DATA.SQL html/APP-META.INI

echo +++ Sleeping...
sleep 30

echo +++ Replacing site url...
docker-compose run --rm wordpress-cli search-replace "https://www.$DOMAIN" "https://blog.$LOCAL_DOMAIN" --all-tables

echo +++ Replacing www directory...
docker-compose run --rm wordpress-cli search-replace $WEBROOT $LOCAL_WEBROOT --all-tables

echo +++ Deactivate plugin insert-headers-and-footers
docker-compose run --rm wordpress-cli wp plugin deactivate insert-headers-and-footers

echo +++ Ready...
