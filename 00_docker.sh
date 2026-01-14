#!/bin/bash

# ==============================================================================
# Script de Instalación de Docker y Docker Compose (Plugin)
# Basado en: https://github.com/gdiazes/sgd/blob/main/lab10/01_Install_contenedores.md
# Autor: Linux Specialist AI
# SO Objetivo: Ubuntu / Debian
# ==============================================================================

# Colores para salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO] Iniciando script de instalación de Docker...${NC}"

# 1. Verificación de permisos de root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Por favor, ejecuta este script como root o usando sudo.${NC}"
  exit 1
fi

# 2. Eliminación de paquetes antiguos (Limpieza)
echo -e "${BLUE}[INFO] Eliminando versiones antiguas o conflictivas...${NC}"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    apt-get remove -y $pkg 2>/dev/null
done

# 3. Actualización de repositorios e instalación de dependencias
echo -e "${BLUE}[INFO] Actualizando lista de paquetes e instalando pre-requisitos...${NC}"
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

# 4. Configuración de la clave GPG oficial de Docker
echo -e "${BLUE}[INFO] Agregando clave GPG oficial de Docker...${NC}"
install -m 0755 -d /etc/apt/keyrings
# Si la llave ya existe, la sobrescribimos para asegurar que está actualizada
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 5. Configuración del Repositorio
echo -e "${BLUE}[INFO] Agregando el repositorio a Apt sources...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6. Instalación de Docker Engine
echo -e "${BLUE}[INFO] Instalando Docker Engine, CLI, Containerd y Plugins...${NC}"
apt-get update
# Se instala docker-ce, el cli, containerd y los plugins modernos (buildx y compose)
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 7. Habilitar y arrancar el servicio
echo -e "${BLUE}[INFO] Habilitando servicio Docker...${NC}"
systemctl enable docker
systemctl start docker

# 8. Post-instalación: Agregar usuario actual al grupo docker
# Nota: Detectamos el usuario que invocó sudo (SUDO_USER) para no agregar a 'root'
REAL_USER=${SUDO_USER:-$USER}

if [ "$REAL_USER" != "root" ]; then
    echo -e "${BLUE}[INFO] Agregando al usuario '$REAL_USER' al grupo 'docker'...${NC}"
    usermod -aG docker "$REAL_USER"
    echo -e "${GREEN}[OK] Usuario agregado. Necesitarás cerrar sesión y volver a entrar para que surta efecto.${NC}"
else
    echo -e "${BLUE}[WARN] El script se ejecutó como root puro. No se agregó usuario al grupo docker.${NC}"
fi

# 9. Verificación
echo -e "${BLUE}[INFO] Verificando versión instalada...${NC}"
docker --version
docker compose version

echo -e "${GREEN}[EXITO] La instalación ha finalizado.${NC}"
echo -e "${BLUE}[INFO] Ejecutando prueba 'hello-world'...${NC}"
docker run --rm hello-world

echo -e "\n========================================================"
echo -e "${GREEN}INSTALACIÓN COMPLETA${NC}"
echo -e "Si ves el mensaje de 'Hello from Docker!' arriba, todo está correcto."
echo -e "IMPORTANTE: Para usar docker sin 'sudo', cierra sesión y vuelve a entrar."
echo -e "========================================================"
