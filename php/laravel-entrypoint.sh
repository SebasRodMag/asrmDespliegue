#!/bin/sh
#Hacemos que el contenedor se auto genere en /var/www/.env a partir de .env.template cada vez que arranca
set -e

cd /var/www

# Si no existe .env, lo creamos desde la plantilla (montada por compose)
if [ ! -f .env ]; then
    if [ -f .env.template ]; then
        cp .env.template .env
        echo "[entrypoint] Creado /var/www/.env desde .env.template"
    elif [ -f .env.example ]; then
        cp .env.example .env
        echo "[entrypoint] Creado /var/www/.env desde .env.example"
    else
        echo "[entrypoint] ERROR: no hay .env.template ni .env.example" >&2
        exit 1
    fi
fi

# Si APP_KEY está vacío en el .env, se genera uno nuevo
# (si ya existe, no se sobre scribe para no invalidar sesiones)
if ! grep -q '^APP_KEY=base64:' .env || grep -q '^APP_KEY=$' .env; then
    php artisan key:generate --force || true
    echo "[entrypoint] APP_KEY generado en .env"
fi

# Esperar a MySQL si se definió
if [ -n "${DB_HOST:-}" ] && [ -n "${DB_PORT:-}" ]; then
    echo "[entrypoint] Esperando a MySQL en $DB_HOST:$DB_PORT..."
    for i in $(seq 1 30); do
        ( nc -z "$DB_HOST" "$DB_PORT" >/dev/null 2>&1 ) && break
        sleep 2
    done
fi

# Se limpia la cache y se migra
php artisan optimize:clear || true
php artisan migrate --force || true

# Se lanza PHP-FPM
exec php-fpm -F
