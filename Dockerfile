FROM php:7.1-apache

LABEL vendor="Mautic"
LABEL maintainer="Luiz Eduardo Oliveira Fonseca <luiz@powertic.com>"

# Install PHP extensions
RUN apt-get update && apt-get install --no-install-recommends -y \
    cron \
    git \
    wget \
    sudo \
    libc-client-dev \
    libicu-dev \
    libkrb5-dev \
    libmcrypt-dev \
    libssl-dev \
    libz-dev \
    unzip \
    zip \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/cron.daily/*

RUN docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install imap intl mbstring mcrypt mysqli pdo_mysql zip opcache bcmath\
    && docker-php-ext-enable imap intl mbstring mcrypt mysqli pdo_mysql zip opcache bcmath

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Define Mautic volume to persist data
#VOLUME ./

# By default enable cron jobs
ENV MAUTIC_RUN_CRON_JOBS true

# Setting an root user for test
ENV MAUTIC_DB_USER root
ENV MAUTIC_DB_NAME mautic

# Setting PHP properties
ENV PHP_INI_DATE_TIMEZONE='UTC' \
	PHP_MEMORY_LIMIT=512M \
	PHP_MAX_UPLOAD=128M \
	PHP_MAX_EXECUTION_TIME=300

# Download package and extract to web volume
#RUN curl -o mautic.zip -SL https://github.com/mautic/mautic/releases/download/${MAUTIC_VERSION}/${MAUTIC_VERSION}.zip \
#	&& echo "$MAUTIC_SHA1 *mautic.zip" | sha1sum -c - \
#	&& mkdir /usr/src/mautic \
#	&& unzip mautic.zip -d /usr/src/mautic \
#	&& rm mautic.zip \
#	&& chown -R www-data:www-data /usr/src/mautic

#RUN mkdir /usr/src/mautic
WORKDIR /var/www/html
COPY . .
RUN chown -R www-data:www-data .
RUN composer install


# Copy init scripts and custom .htaccess
COPY common/docker-entrypoint.sh /entrypoint.sh
COPY common/makeconfig.php /makeconfig.php
COPY common/makedb.php /makedb.php
COPY common/mautic.crontab /etc/cron.d/mautic
RUN chmod 644 /etc/cron.d/mautic

# Enable Apache Rewrite Module
RUN a2enmod rewrite

# Apply necessary permissions
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]

RUN chown -R www-data:www-data .
CMD ["apache2-foreground"]