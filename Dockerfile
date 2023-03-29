# Extend from preconfigured image
# @see https://hub.docker.com/_/drupal/tags
# @see https://www.drupal.org/requirements/php#drupalversions
FROM drupal:php8.1-apache
ARG env
#To allow install php package https://hub.docker.com/_/php
RUN rm /etc/apt/preferences.d/no-debian-php
#Build image
RUN echo "Install basic libraries"
RUN a2enmod rewrite
# Set default timezone
RUN ln -fs /usr/share/zoneinfo/America/Toronto /etc/localtime &&  \
    dpkg-reconfigure --frontend noninteractive tzdata
# Install apachetop for debugging
RUN apt-get update &&  \
    apt-get install -y apachetop libcurl4-openssl-dev
# Install the PHP extensions we need
RUN apt-get update &&  \
    apt-get install -y wget vim git mariadb-client libzip-dev libldap2-dev parallel zip unzip apachetop libcurl4-openssl-dev
# Install lib to gb
RUN apt-get update &&  \
    apt-get install -y libpng-dev libjpeg-dev libonig-dev
# Configure PHP GD extension
RUN docker-php-ext-configure gd --with-jpeg
# Install PHP extensions
RUN docker-php-ext-install gd curl mbstring opcache pdo pdo_mysql zip
# Configure and install PHP LDAP extension
RUN docker-php-ext-configure ldap
RUN docker-php-ext-install ldap

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# Clean build dependencies
RUN rm -rf /var/lib/apt/lists/*

#Installation ImageMagick
RUN apt-get update &&  \
    apt-get install -y imagemagick ghostscript libmagickwand-dev fonts-droid-fallback --no-install-recommends
RUN pecl install imagick
RUN docker-php-ext-enable imagick

#Installation of Redis
RUN pecl install redis \
    && docker-php-ext-enable redis

#Copy server config files
RUN rm /etc/apache2/sites-available/000-default.conf
COPY /docker/config/000-default.conf /etc/apache2/sites-available/000-default.conf
# set recommended PHP.ini settings
COPY docker/config/php.ini /usr/local/etc/php/php.ini
# see https://secure.php.net/manual/en/opcache.installation.php
COPY docker/config/opcache.ini /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN echo "Update PATH variable to include Composer binaries."
ENV PATH "/root/.composer/vendor/bin:$PATH"

# Build GCS
# Copy settings
WORKDIR /var/www/html
COPY . /var/www/html
RUN chown -R www-data:www-data /var/www/html

#composer install -n --prefer-dist --no-dev
RUN composer install --optimize-autoloader
#RUN composer install -n --prefer-dist --no-dev

# Configure drush
RUN ln -sf /var/www/html/vendor/bin/drush /usr/bin/drush

# Config for local env
RUN \
if [ "$env" = "local" ]; \
    then echo "Installation of XDebug"; \
         cp /var/www/html/docker/config/drupal-*.ini /usr/local/etc/php/conf.d/; \
         cp /var/www/html/docker/script/installDrupal.sh /usr/bin/installDrupal; \
         chmod +x /usr/bin/installDrupal; \
         cp /var/www/html/docker/script/installDB.sh /usr/bin/installDB; \
         chmod +x /usr/bin/installDB; \
         cp /var/www/html/docker/script/backupDB.sh /usr/bin/backupDB; \
         chmod +x /usr/bin/backupDB; \
         pecl install xdebug-3.1.5; \
         docker-php-ext-enable xdebug; \
         mkdir /var/run/secrets; \
         mkdir /var/run/secrets/vdmtl; \
         mkdir /var/run/secrets/vdmtl/redis; \
         mkdir /var/log/xdebug; \
         echo '' > /var/run/secrets/vdmtl/redis/password; \
         echo 'redis' > /var/run/secrets/vdmtl/redis/host; \
         echo '6379' > /var/run/secrets/vdmtl/redis/port; \
         curl -fsSL https://deb.nodesource.com/setup_16.x | bash -; \
         apt-get update; \
         apt-get install -y nodejs chromium; \
         apt-get install -y ssl-cert; \
         rm -r /var/lib/apt/lists/*; \
         a2enmod ssl; \
         a2ensite default-ssl; \
         rm /etc/apache2/sites-available/default-ssl.conf; \
         cp /var/www/html/docker/config/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf; \
fi;

RUN echo "CMD apachectl -D FOREGROUND"
CMD apachectl -D FOREGROUND
