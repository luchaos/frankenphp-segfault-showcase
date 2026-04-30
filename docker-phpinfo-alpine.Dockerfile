FROM dunglas/frankenphp:1-php8.4.20-alpine

RUN install-php-extensions pcntl && docker-php-ext-enable pcntl

RUN adduser -D www-data; \
    setcap -r /usr/local/bin/frankenphp; \
    chown -R www-data:www-data /config/caddy /data/caddy

COPY --chown=www-data . .

ENTRYPOINT ["sh","-c","exec php -i"]
