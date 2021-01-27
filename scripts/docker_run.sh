#!/bin/bash
# ------------------------------------------------------------------
# [Mario Maksimovikj] Build/Run docker container for this project
# ------------------------------------------------------------------

SUBJECT=819c762e-7274-4f5f-a3b6-2ebce7929672

# --- Locks -------------------------------------------------------
LOCK_FILE=/tmp/$SUBJECT.lock
if [ -f "$LOCK_FILE" ]; then
    echo "$(basename $0)" " is already running"
    exit
fi

trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE

# --- Body --------------------------------------------------------
docker network create wp-network || echo 'Network "wp-network" already created!'

# DB Variables
DB_HOST=wp-mysql
DB_USER=user
DB_PASS=user123
DB_ROOT_PASS=root123
DB_NAME=wp-test
DB_TABLE_PREFIX=wp

# Start mysql db container
mkdir -p mysql

docker run --name wp-mysql \
    --network=wp-network \
    --hostname=wp-mysql \
    --user $(id -u $USER):$(id -g $GROUP) \
    -v "$(pwd)"/mysql:/var/lib/mysql \
    -e MYSQL_DATABASE=$DB_NAME \
    -e MYSQL_USER=$DB_USER \
    -e MYSQL_PASSWORD=$DB_PASS \
    -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASS \
    -p 3307:3306 \
    -d mysql:5.7.32

#The following environment variables are also honored for configuring your WordPress instance:
docker run -it --rm --name=wp-apache \
    --network=wp-network \
    --hostname=wp-apache \
    -p 80:80 \
    -v /tmp:/tmp \
    -v "$(pwd)"/wp:/var/www/html \
    -e WORDPRESS_DB_HOST=$DB_HOST \
    -e WORDPRESS_DB_USER=$DB_USER \
    -e WORDPRESS_DB_PASSWORD=$DB_PASS \
    -e WORDPRESS_DB_NAME=$DB_NAME \
    -e WORDPRESS_TABLE_PREFIX=$DB_TABLE_PREFIX \
    wordpress:php7.4-apache

# removing related containers
# docker rm -f wp-apache
docker rm -f wp-mysql

DANGLING=$(docker images -f "dangling=true" -q)
if [ "x""$DANGLING" != "x" ]; then
    docker rmi $DANGLING
fi

echo "Successfuly destroyed all linked containers"

exit 0
