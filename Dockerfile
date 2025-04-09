# syntax=docker/dockerfile:1.5
FROM php:8.3-apache AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libpng-dev \
    libpq-dev \
    libzip-dev \
    locales \
    mariadb-client \
    openssh-client \
    rsync \
    sqlite3 \
    sudo \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg=/usr && \
    docker-php-ext-install -j "$(nproc)" gd intl opcache pdo_mysql zip

# Configure PHP settings
RUN echo 'memory_limit = -1' > /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
    { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini && \
    { \
    echo 'log_errors=On'; \
    echo 'error_log=/dev/stderr'; \
    echo 'error_reporting=-1'; \
    } > /usr/local/etc/php/conf.d/logs.ini

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set environment variables
ENV TERM=xterm \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1 \
    SIMPLETEST_BASE_URL='http://localhost' \
    SIMPLETEST_DB='sqlite://localhost/sites/default/files/.ht.sqlite'

# Expose port 80
EXPOSE 80

# Stage 2: Final application image
FROM builder AS site

# Copy the application files
COPY app /app

# Set the working directory
WORKDIR /app/web

# Install Composer dependencies
RUN --mount=type=cache,target=/root/.composer/cache \
    composer require drush/drush --dev --no-update && \
    composer require palantirnet/drupal-rector mglaman/drupal-check --dev --no-update && \
    if [ -f /app/composer.lock ]; then composer install; else composer update; fi && \
    cp vendor/palantirnet/drupal-rector/rector.php .

# Create a symbolic link to the web directory
RUN rm -rf /var/www/html && ln -sf /app/web /var/www/html

# Set the permissions
RUN chown -R www-data:www-data sites modules themes

# Set the PATH environment variable
ENV PATH=${PATH}:/app/bin:/app/vendor/bin