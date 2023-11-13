#!/bin/bash

#Muestra todos los comandos que se van ejecutando
set -x

#Actualizar los repositorios
apt update

#Acltualizamos los paquetes
apt upgrade -y

#Instalamos el servidor web Apache
apt install apache2 -y

#Instalamos el sistema de gestores de base de datos MySQL
apt install mysql-server -y

#Instalamos PHP
apt install php libapache2-mod-php php-mysql -y

#Reinciamos el servicio de Apache
systemctl restart apache2.service

# Eliminamos el contenido del 000-default.conf anteriormente creado
rm -rf /etc/apache2/sites-available/000-default.conf

#Sustituimos el 000-default.conf de apache por el creado por nosotros 
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf