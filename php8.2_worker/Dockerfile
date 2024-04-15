# Use the official php image
FROM php:8.2-cli AS build

ENV TZ=Europe/Berlin

# Add dependencies
RUN apt update \
    && apt dist-upgrade -y \
    && apt install -y --no-install-recommends \
        ca-certificates \
        cron \
        supervisor \
        unzip \
        zip \
        cmake \
        cron \
        libfreetype6-dev \
        libfontconfig1-dev \
        libxml++2.6-dev \
        libjpeg-dev \
        libssl-dev \
        libzip-dev \
        libmagickwand-dev \
        libwebp-dev \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install php extensions
RUN docker-php-ext-configure gd \
        --with-jpeg=/usr/include/ \
        --with-freetype=/usr/include/ \
        --with-webp=/usr/include/ \
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
    && pecl install imagick \
    && pecl install redis \
    && docker-php-ext-enable \
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
        zip \
        redis

RUN apt-get purge -y --auto-remove gcc g++ make \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set timezone
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

# PHP configuration 
RUN ln -s /usr/bin/php8 /usr/bin/php \ 
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY ./config/fpm/conf.d/custom.ini "$PHP_INI_DIR/conf.d/custom.ini"

# www-data crontab for laravel artisan schedule
COPY --chown=root:crontab ./config/cron/www-data /var/spool/cron/crontabs/root
RUN chmod 0600 /var/spool/cron/crontabs/root

# Add Supervisord config
COPY ./config/supervisord/ /etc/

# Healthcheck
#COPY ./healthcheck.sh /healthcheck.sh
#HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/healthcheck.sh"]

WORKDIR /app

# Entrypoint and command
ENTRYPOINT ["/usr/bin/supervisord", "-c"] 
CMD ["/etc/supervisor/supervisord.conf"]
