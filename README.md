# php-base-image for laravel

PHP base image for Laravel with PHP version 8.2 and 8.3 debian based.
The image contains important packages for laravel.

Dockerhub:
https://hub.docker.com/r/falki141/php-base-image

Packages are included (nginx is not included in workers and frankenphp):

* nginx
* cron
* supervisor
* dom
* ctype
* exif
* gd
* intl
* opcache
* pdo
* pdo_mysql
* session
* phar
* xml
* fileinfo
* simplexml
* sockets
* zip
* phpredis

# Mountpoint
Please mount your application into /app. This is the default path.

Example:

```bash
docker run -p 8080:80 -d --name test -v $PWD:/app -d falki141/php-base-image:8.3-all-in
```

Frankenphp example without SSL:
```bash
docker run -p 8080:80 -d --name test -v $PWD:/app -e CADDY_GLOBAL_OPTIONS="auto_https off" -e SERVER_NAME="http://localhost" -d falki141/php-base-image:frankenphp8.3
```