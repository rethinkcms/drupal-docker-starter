# Stage 1: Build the application
FROM php:8.3-apache as builder

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client git rsync unzip locales mariadb-client libicu-dev sqlite3 sudo

# Install PHP extensions
RUN apt-get install -y --no-install-recommends \
    libfreetype6-dev libjpeg-dev libpng-dev libpq-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg=/usr \
    && docker-php-ext-install -j "$(nproc)" gd opcache pdo_mysql zip intl

# Configure PHP settings
RUN echo 'memory_limit = -1' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini
RUN { \
    echo 'log_errors=On'; \
    echo 'error_log=/dev/stderr'; \
    echo 'error_reporting=-1'; \
    } > /usr/local/etc/php/conf.d/logs.ini

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set environment variables
ENV TERM xterm
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1
ENV SIMPLETEST_BASE_URL='http://localhost'
ENV SIMPLETEST_DB='sqlite://localhost/sites/default/files/.ht.sqlite'

# Expose port 80
EXPOSE 80

# Stage 2: Final application image
FROM builder as site

# Set the working directory
WORKDIR /app

# Copy the application files
COPY app /app

# Install Composer dependencies
RUN \
    --mount=type=cache,mode=0777,target=/root/.composer/cache \
    composer require drupal/core-dev drush/drush --dev --no-update && \
    composer require palantirnet/drupal-rector mglaman/drupal-check --dev --no-update

# Run Composer install if composer.lock exists, otherwise run composer update
RUN \
    --mount=type=cache,mode=0777,target=/root/.composer/cache \
    if [ -f /app/composer.lock ]; then composer install; else composer update; fi
    
RUN cp vendor/palantirnet/drupal-rector/rector.php .

# Create a symbolic link to the web directory
RUN rm -rf /var/www/html && ln -sf /app/web /var/www/html

# Set the permissions
RUN chown -R www-data:www-data web/sites web/modules web/themes

# Set the PATH environment variable
ENV PATH=${PATH}:/app/bin:/app/vendor/bin