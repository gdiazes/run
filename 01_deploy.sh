#!/bin/bash

# ==============================================================================
# Script de Despliegue Lab 11: Docker Compose (WordPress + MySQL)
# Basado en: https://github.com/gdiazes/sgd/tree/main/lab11
# Autor: Linux Specialist AI
# ==============================================================================

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="lab11_wordpress"
PORT_EXT=8080

echo -e "${BLUE}[INFO] Iniciando automatización del Lab 11 (Docker Compose)...${NC}"

# 1. Comprobación de pre-requisitos
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERROR] Docker no está instalado. Ejecuta primero el script del Lab 10.${NC}"
    exit 1
fi

# Comprobar si el plugin compose funciona
if ! docker compose version &> /dev/null; then
    echo -e "${RED}[ERROR] Docker Compose no detectado.${NC}"
    exit 1
fi

# 2. Creación del entorno de trabajo
echo -e "${BLUE}[INFO] Creando directorio del proyecto: ${PROJECT_DIR}...${NC}"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit

# 3. Generación del archivo docker-compose.yml
# Como especialista, configuro esto para que sea robusto:
# - Versión de MySQL estable (5.7 o 8.0) para compatibilidad.
# - Volúmenes persistentes para que no pierdas datos al reiniciar.
# - Red interna automática.

echo -e "${BLUE}[INFO] Generando archivo docker-compose.yml...${NC}"

cat <<EOF > docker-compose.yml
services:
  # Servicio de Base de Datos
  db:
    image: mysql:5.7
    container_name: lab11_db
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wp_user
      MYSQL_PASSWORD: wp_password

  # Servicio de WordPress
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    container_name: lab11_wp
    ports:
      - "${PORT_EXT}:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wp_user
      WORDPRESS_DB_PASSWORD: wp_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html

# Definición de volúmenes persistentes
volumes:
  db_data:
  wp_data:
EOF

echo -e "${GREEN}[OK] Archivo docker-compose.yml generado exitosamente.${NC}"

# 4. Despliegue de los contenedores
echo -e "${BLUE}[INFO] Levantando los servicios en segundo plano (detached mode)...${NC}"
echo -e "${BLUE}[INFO] Esto puede tardar unos minutos mientras descarga las imágenes...${NC}"

docker compose up -d

# 5. Verificación del estado
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}[EXITO] Despliegue completado.${NC}"
    echo -e "Estado de los contenedores:"
    docker compose ps
    
    IP_ADDR=$(hostname -I | cut -d' ' -f1)
    echo -e "\n========================================================"
    echo -e " ACCESO AL SERVICIO:"
    echo -e " Abre en tu navegador: http://${IP_ADDR}:${PORT_EXT}"
    echo -e " O localmente:         http://localhost:${PORT_EXT}"
    echo -e "========================================================"
else
    echo -e "${RED}[ERROR] Hubo un problema al levantar los contenedores.${NC}"
fi
