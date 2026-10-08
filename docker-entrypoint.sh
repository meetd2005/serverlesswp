#!/bin/sh
set -e
PORT="${PORT:-80}"
sed -ri "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf
# Never ship a stale config cache; the app must read the runtime environment.
rm -f /var/www/html/vapi/bootstrap/cache/config.php
exec "$@"
