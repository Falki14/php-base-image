# Use the official frankenphp image
FROM dunglas/frankenphp:latest-php8.3-bookworm

ENV TZ=Europe/Berlin

# Add dependencies
RUN apt update \
    && apt dist-upgrade -y \
    && apt install libzip-dev libjpeg-dev libpng-dev libfreetype6-dev libxml++2.6-dev libssl-dev -y

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
    && pecl install redis \
    && docker-php-ext-enable \
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
        redis

# Set timezone
RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone
