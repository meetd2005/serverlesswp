FROM php:7.4-apache

RUN docker-php-ext-install mysqli pdo_mysql
RUN apt-get update \
    && apt-get install -y libzip-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install zip
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Serve Laravel's public/ directory through Apache with mod_rewrite enabled.
# Without this every route (including /vapi) 404s, because requests never reach index.php.
ENV APACHE_DOCUMENT_ROOT=/var/www/html/vapi/public
RUN a2enmod rewrite \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}/!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && sed -ri -e 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf

COPY ./vapi /var/www/html/vapi
RUN mkdir -p /var/www/html/vapi/storage/framework/cache /var/www/html/vapi/storage/framework/sessions \
        /var/www/html/vapi/storage/framework/views /var/www/html/vapi/storage/logs /var/www/html/vapi/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/vapi/storage /var/www/html/vapi/bootstrap/cache

RUN echo "flag{ssrf_e0pgt3az9zeqdd4fhatc}" > /flag.txt

# PaaS hosts (Render, Railway, Heroku, ...) inject $PORT; fall back to 80 locally.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
