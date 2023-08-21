# use the official php image
FROM php:8.2-fpm AS build

# add dependencies
RUN apt update && \
    apt dist-upgrade -y && \
    apt install -y --no-install-recommends \
        cmake \
        libfreetype6-dev \
        libfontconfig1-dev \
        libxml++2.6-dev \
        libjpeg-dev \
        libssl-dev \
        libzip-dev \
        libmagickwand-dev 

# install php extensions
RUN docker-php-ext-configure gd \
        --with-jpeg=/usr/include/ \
        --with-freetype=/usr/include/ && \
    docker-php-ext-install -j$(nproc) \
        dom \
        ctype \
        exif \
        gd \
        intl \
        opcache \
        pdo \
        pdo_mysql \
        session \
        phar \
        xml \
        fileinfo \
        simplexml \
        sockets \
        zip && \
    pecl install imagick 

FROM php:8.2-fpm AS final

ARG user=www-data
ARG group=${user}

ENV TZ=Europe/Berlin
ENV NGINX_PORT=80

# add apt packages
RUN apt update && \
    apt dist-upgrade -y && \
    apt install -y --no-install-recommends ca-certificates \
        cron \
        nginx \
        supervisor \
        unzip \
        zip \
        libjpeg-dev \
        libssl-dev \
        libzip-dev \
        libmagickwand-dev

# enable php extensions
COPY --from=build /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
RUN docker-php-ext-enable \
    dom \
    ctype \
    exif \
    gd \
    imagick \
    intl \
    opcache \
    pdo \
    pdo_mysql \
    session \
    phar \
    xml \
    fileinfo \
    simplexml \
    sockets \
    zip

# set timezone
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone 

# php configuration 
RUN ln -s /usr/bin/php8 /usr/bin/php &&\ 
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY ./config/fpm/pool.d/app.conf  /usr/local/etc/php-fpm.d/www.conf
COPY ./config/fpm/conf.d/custom.ini "$PHP_INI_DIR/conf.d/custom.ini"

#
# nginx configuration
COPY ./config/nginx/default /etc/nginx/conf.d/default.conf
COPY ./config/nginx/nginx.conf /etc/nginx/

# www-data crontab for laravel artisan schedule
COPY --chown=root:${group} ./config/cron/www-data /etc/crontabs/
RUN chmod 0600 /etc/crontabs/www-data

# add supervisor config
COPY ./config/supervisord/ /etc/

# nginx port
EXPOSE $NGINX_PORT

# healthcheck
#COPY ./healthcheck.sh /healthcheck.sh
#HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/healthcheck.sh"]

WORKDIR /var/www

# entrypoint and command
ENTRYPOINT ["/usr/bin/supervisord", "-c"] 
CMD ["/etc/supervisor/supervisord.conf"]