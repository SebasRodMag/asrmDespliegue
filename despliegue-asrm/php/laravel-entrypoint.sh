#!/bin/sh
set -eu

cd /var/www

# Si el .env es es un directorio, avisa y aborta con un mensaje
if [ -d .env ]; then
    echo "[entrypoint] ERROR: /var/www/.env es un DIRECTORIO."
    echo "  Causa típica: un bind-mount pasado (p.ej.: ./despliegue-asrm/laravel/.env.prod:/var/www/.env:ro)."
    echo "  Solución: elimina esa línea del docker-compose.yml y recrea el contenedor."
    exit 1
fi

# Crear .env si no existe
if [ ! -f .env ]; then
    if [ -f .env.template ]; then
        cp -f .env.template .env
        echo "[entrypoint] Creado /var/www/.env desde .env.template"
    elif [ -f .env.example ]; then
        cp -f .env.example .env
        echo "[entrypoint] Creado /var/www/.env desde .env.example"
    else
        echo "[entrypoint] ERROR: no hay .env.template ni .env.example en /var/www" >&2
        exit 1
    fi
fi

# Si hace falta, se generar APP_KEY
if ! grep -q '^APP_KEY=base64:' .env || grep -q '^APP_KEY=$' .env; then
    php artisan key:generate --force || true
    echo "[entrypoint] APP_KEY generado en .env"
fi

# Esperar a MySQL si hay vars
if [ -n "${DB_HOST:-}" ] && [ -n "${DB_PORT:-}" ]; then
    echo "[entrypoint] Esperando MySQL en $DB_HOST:$DB_PORT..."
    for i in $(seq 1 30); do
        ( nc -z "$DB_HOST" "$DB_PORT" >/dev/null 2>&1 ) && break
        sleep 2
    done
fi

php artisan optimize:clear || true
php artisan migrate --force || true

exec php-fpm -F
