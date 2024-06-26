#!/bin/bash

#Muestra todos los comandos que se van ejecutando
set -x

#Actualizar los repositorios
apt update

#Incluimos las variabkes de archivo .en
source .env

# Eliminamos descargas previas de wp-cli
rm -rf /tmp/wp-cli.phar

# Habilitammos el modúlo rewrite
a2enmod rewrite

# Copiamos el archivo de php 
cp ../php/index.php /var/www/html

# Modificamos el propietario y el grupo del directorio /var/www/html
chown -R www-data:www-data /var/www/html

# Descargamos la última versión de WP-CLI con el comando wget.
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

# Le asignamos los permisos de ejecución
chmod +x /tmp/wp-cli.phar

# Movemos el archivo wp-cli.phar al directorio /usr/local/bin/ con el nombre wp
mv /tmp/wp-cli.phar /usr/local/bin/wp

# Eliminamos instalaciones previas de WordPress
rm -rf /var/www/html/*

# Descargamos el código fuete de WordPress en var/www/html
wp core download --locale=es_ES --path=/var/www/html --allow-root

# Creamos base de datos y el usuario de la base de datos
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# Creamos el archivo wp-config
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --path=/var/www/html \
  --allow-root 

# Instalamos WordPress
wp core install \
  --url=$CERTIFICATE_DOMAIN \
  --title="$WORDPRESS_TITLE" \
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASS \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html \
  --allow-root

#Instalamos un theme

wp theme install sydney --activate --path=/var/www/html --allow-root

#Instalamos varios plugins

wp plugin install wps-hide-login --activate --path=/var/www/html --allow-root
wp plugin install permalink-manager --activate --path=/var/www/html --allow-root
wp plugin install woocommerce --activate --path=/var/www/html --allow-root

# Instalamos un tema
wp theme install sydney --activate --path=/var/www/html --allow-root

# Actualizamos los pugins 
wp core update --path=/var/www/html --allow-root

# Actualizamos los temas 
wp theme update --all --path=/var/www/html --allow-root

# Modificamos el la estructuras de la cabecera
wp rewrite structure '/%postname%/' --path=/var/www/html --allow-root

# Modificamos el nombre de la pagina de administrador
wp option update whl_page 'samueladmin' --path=/var/www/html --allow-root

# Copiamos el nuevo archivo .htaccess
cp ../htaccess/.htaccess /var/www/html

#Modificamos el propietario y el grupo del directorio /var/www/html
chown -R www-data:www-data /var/www/html

#Reiniciamos el servicio de Apache
systemctl restart apache2
