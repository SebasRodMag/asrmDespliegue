#!/bin/bash
set -e

echo "[DESPLIEGUE] Entrando en /opt/asrm-stack"
cd /opt/asrm-stack

echo "[DESPLIEGUE] Actualizando repositorio..."
git pull

echo "[DESPLIEGUE] Bajando contenedores antiguos..."
docker compose down

echo "[DESPLIEGUE] Levantando contenedores nuevos..."
docker compose up -d --build

echo "[DESPLIEGUE] Despliegue completado."
