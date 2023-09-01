# Use the official php image
FROM php:8.2-fpm AS build

# Add dependencies
RUN apt update \
    && apt dist-upgrade -y \
    && apt install -y --no-install-recommends \
        cmake \
        libfreetype6-dev \
        libfontconfig1-dev \
        libxml++2.6-dev \
        libjpeg-dev \
        libssl-dev \
        libzip-dev \
        libmagickwand-dev 
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install php extensions
RUN docker-php-ext-configure gd \
        --with-jpeg=/usr/include/ \
        --with-freetype=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
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
        zip \
    && pecl install imagick 

FROM php:8.2-fpm AS final

ARG user=www-data
ARG group=${user}

ENV TZ=Europe/Berlin \
    NGINX_PORT=80

# Add apt packages
RUN apt update \
    && apt dist-upgrade -y \
    && apt install -y --no-install-recommends \
        ca-certificates \
        cron \
        nginx \
        supervisor \
        unzip \
        zip \
        libjpeg-dev \
        libzip-dev \
        libmagickwand-dev \
    && apt-get purge -y --auto-remove gcc g++ make
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable php extensions
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

# Set timezone
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && useradd -s /bin/false nginx

# PHP configuration 
RUN ln -s /usr/bin/php8 /usr/bin/php \ 
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY ./config/fpm/pool.d/app.conf  /usr/local/etc/php-fpm.d/www.conf
COPY ./config/fpm/conf.d/custom.ini "$PHP_INI_DIR/conf.d/custom.ini"

# Nginx configuration
COPY ./config/nginx/default /etc/nginx/conf.d/default.conf
COPY ./config/nginx/nginx.conf /etc/nginx/

# www-data crontab for laravel artisan schedule
COPY --chown=root:${group} ./config/cron/www-data /etc/crontabs/
RUN chmod 0600 /etc/crontabs/www-data \
    && rm /usr/local/etc/php-fpm.d/docker.conf \
    && rm /usr/local/etc/php-fpm.d/zz-docker.conf \
    && rm /etc/nginx/sites-enabled/default

# Add Supervisord config
COPY ./config/supervisord/ /etc/

# Nginx port
EXPOSE $NGINX_PORT

# Healthcheck
#COPY ./healthcheck.sh /healthcheck.sh
#HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/healthcheck.sh"]

WORKDIR /var/www

# Entrypoint and command
ENTRYPOINT ["/usr/bin/supervisord", "-c"] 
CMD ["/etc/supervisor/supervisord.conf"]