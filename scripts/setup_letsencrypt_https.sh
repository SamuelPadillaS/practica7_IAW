#!/bin/bash

#Muestra todos los comandos que se van ejecutando y si ocurre algun error continua con el script
set -ex

# Actualizamos los repositorio
apt update -y

#Actualizamos los paquetes
apt upgrade -y

#Importamos el archivo de variables .env
source .env

#Instalamos y actualizamos snapd
snap install core
snap refresh core

#Eliminamos cualuquier instalación previa de certbot con apt
apt remove certbot

#Instalamos la aplicación certbot
snap install --classic certbot

#Creamos un alias para la aplicación certbot
ln -sf /snap/bin/certbot /usr/bin/certbot

#Ejecutamos el comando certbot

certbot --apache -m $CERTIFICATE_MAIL --agree-tos --no-eff-email -d $CERTIFICATE_DOMAIN --non-interactive
