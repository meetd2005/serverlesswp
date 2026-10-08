#!/bin/sh
set -e
PORT="${PORT:-80}"
sed -ri "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf
# Never ship a stale config cache; the app must read the runtime environment.
rm -f /var/www/html/vapi/bootstrap/cache/config.php

# Start the bundled database unless an external/compose one is configured.
case "${DB_HOST}" in
  127.0.0.1|localhost)
    mkdir -p /run/mysqld /var/lib/mysql
    chown -R mysql:mysql /run/mysqld /var/lib/mysql
    [ -d /var/lib/mysql/mysql ] || mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null
    mysqld_safe --user=mysql --bind-address=127.0.0.1 --skip-networking=0 >/var/log/mysqld.log 2>&1 &
    for i in $(seq 1 60); do mysqladmin ping --silent 2>/dev/null && break; sleep 1; done
    if ! mysql -e "USE \`${DB_DATABASE}\`" 2>/dev/null; then
      mysql -e "CREATE DATABASE \`${DB_DATABASE}\`"
      mysql "${DB_DATABASE}" < /docker-initdb/vapi.sql
    fi
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('${DB_PASSWORD}'); FLUSH PRIVILEGES;" 2>/dev/null || true
    ;;
esac
exec "$@"
