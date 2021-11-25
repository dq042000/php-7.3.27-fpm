FROM php:7.3.27-fpm
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \ 
        libzip-dev \
        libpq-dev \ 
        libicu-dev \
        libmagick++-dev

RUN docker-php-ext-configure gd --with-freetype-dir --with-jpeg-dir \
    && docker-php-ext-configure zip --with-libzip \ 
    && docker-php-ext-install -j$(nproc) gd \ 
    && docker-php-ext-install -j$(nproc) mysqli \ 
    && docker-php-ext-install -j$(nproc) pdo_mysql \ 
    && docker-php-ext-install -j$(nproc) pdo_pgsql \ 
    && docker-php-ext-install -j$(nproc) zip \ 
    && docker-php-ext-install -j$(nproc) intl

RUN pecl install imagick-3.4.4 \ 
    && docker-php-ext-enable imagick