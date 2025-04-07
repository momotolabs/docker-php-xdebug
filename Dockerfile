FROM php:8.3-fpm-alpine

ARG USERNAME=docker

# Add required packages and PHP extensions
RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        linux-headers \
        git \
        # PHP extension dependencies
        libzip-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libxml2-dev \
        oniguruma-dev \
        curl-dev \
        openssl-dev \
    # Install permanent runtime dependencies
    && apk add --no-cache \
        libzip \
        libpng \
        libjpeg-turbo \
        freetype \
        libxml2 \
        icu-dev \
        icu-libs \
        mysql-client \
        openssh \
        nodejs \
        npm \
        # Chromium dependencies
        chromium \
        nss \
        harfbuzz \
        ca-certificates \
        ttf-freefont \
    # Configure and install PHP extensions
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        calendar \
        exif \
        gd \
        intl \
        mysqli \
        opcache \
        pdo \
        pdo_mysql \
        pcntl \
        zip \
    # Install PECL extensions
    && pecl install \
        redis-6.0.2 \
        xdebug \
    && docker-php-ext-enable \
        redis \
    # Install Puppeteer and configure Chrome
    && npm install --global --unsafe-perm puppeteer@^17 \
    && mkdir -p /usr/local/share/chrome \
    && ln -s /usr/bin/chromium-browser /usr/local/share/chrome/chrome \
    && ln -s /usr/bin/chromium-browser /usr/local/share/chrome/chromium \
    # Cleanup (but preserve runtime libs)
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/doc/* \
        /usr/share/man/*

# Optimize PHP-FPM and OPcache for production
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configure php.ini for production
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Add configuration files
COPY --chown=$USERNAME:www-data custom-php.ini /usr/local/etc/php/conf.d/
COPY --chown=$USERNAME:www-data xdebug-php.ini /usr/local/etc/php/conf.d/xdebug-php.ini.disabled
COPY --chown=$USERNAME:www-data www.conf /usr/local/etc/php-fpm.d/

# Set up user and permissions
RUN adduser -D -u 1000 $USERNAME \
    && addgroup $USERNAME www-data \
    && chown -R $USERNAME:www-data /var/www/html \
    && chmod -R g+w /var/www/html

# Create entrypoint script to handle Xdebug activation/deactivation
COPY --chown=root:root docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html/

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application files
COPY --chown=$USERNAME:www-data . .

# Healthcheck for PHP-FPM
HEALTHCHECK --interval=30s --timeout=3s CMD php-fpm -t || exit 1

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php-fpm"]