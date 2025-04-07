#!/bin/sh
set -e

if [ "${XDEBUG_ENABLED:-false}" = "true" ] || [ "${XDEBUG_ENABLED}" = "1" ]; then
    echo "Enabling Xdebug..."
    
    if [ -f /usr/local/etc/php/conf.d/xdebug-php.ini.disabled ]; then
        cp /usr/local/etc/php/conf.d/xdebug-php.ini.disabled /usr/local/etc/php/conf.d/xdebug-php.ini
    fi
    
    docker-php-ext-enable xdebug
    
    echo "Xdebug activate"
else
    echo "Deactivate Xdebug..."
    
    if [ -f /usr/local/etc/php/conf.d/xdebug-php.ini ]; then
        rm -f /usr/local/etc/php/conf.d/xdebug-php.ini
    fi
    
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ]; then
        rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    fi
    
    echo "Xdebug inactive"
fi

exec "$@"