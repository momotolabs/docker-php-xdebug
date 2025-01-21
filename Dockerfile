FROM php:8.3-fpm
RUN apt update && apt install -y unixodbc-dev gpg libzip-dev
RUN apt install git build-essential libltdl-dev libpng-dev libjpeg-dev libtiff-dev -y


RUN apt install ghostscript -y
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

RUN apt install -y gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget libgbm-dev libxshmfence-dev \
 && npm install --location=global --unsafe-perm puppeteer@^17 \
 && chmod -R o+rx /usr/lib/node_modules/puppeteer/.local-chromium

RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN apt autoremove && apt clean
ADD ./custom-php.ini /usr/local/etc/php/conf.d/custom-php.ini
ADD ./xdebug-php.ini /usr/local/etc/php/conf.d/xdebug-php.ini
ADD ./www.conf /usr/local/etc/php-fpm.d/www.conf

ENV USERNAME=docker


RUN adduser $USERNAME \
    && usermod -aG www-data $USERNAME \
    && chown -R $USERNAME:www-data /var/www/html \
    && chmod -R g+w /var/www/html

WORKDIR /var/www/html/
COPY --chown=$USERNAME:www-data . .
USER $USERNAME
# Exponer el puerto para el servidor web
EXPOSE 9000
