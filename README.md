# Administración de Wordpress con la utilidad WP-CLI

Antes de comenzar la práctica, tendremos que realizar una sere de archivos para realizarla correctamente:

~~~
.
├── README.md
├── conf
│   └── 000-default.conf
├── htaccess
│   └── .htaccess
└── scripts
    ├── .env
    ├── install_lamp.sh
    ├── setup_letsencrypt_https.sh
    ├── deploy_wordpress_root_directory.sh    
    └── deploy_wordpress_own_directory.sh
~~~

## Contenido **install_lamp.sh**

Ya realizado los archivos necesarios comenzaremos con la creación del contenido del install_lamp.sh

**⚠️!!!IMPORTANTE¡¡¡⚠️**

A la hora de realizar todos nuestros scripts es importante escribir estos dos comandos:

~~~
#!/bin/bash
~~~

Con este comando indicamos al sistema operativo que inicie el shell especificado para ejecutar los comandos que siguen en el script.

~~~
set -x
~~~

Dicho esto ya podemos continuar con la creación 

### 1. Actualizar los repositorios

~~~
apt update
~~~

### 2. Acltualizamos los paquetes

~~~
apt upgrade -y
~~~

### 3. Instalamos el servidor web Apache

~~~
apt install apache2 -y
~~~

### 4. Instalamos el sistema de gestores de base de datos MySQL

~~~
apt install mysql-server -y
~~~

### 5. Instalamos PHP

~~~
apt install php libapache2-mod-php php-mysql -y
~~~

### 6. Eliminamos el contenido del 000-default.conf anteriormente creado

~~~
rm -rf /etc/apache2/sites-available/000-default.conf
~~~

### 7. Sustituimos el 000-default.conf de apache por el creado por nosotros 

~~~
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf
~~~

### 8. Reinciamos el servicio de Apache

~~~
systemctl restart apache2.service
~~~

Cuando realicemos el **install_lamp.sh**, pasaremos con la creación del  archivo **000-default.conf** de configuración del directorio **"conf"** , el archivo **.htaccess** del directorio **"htaccess"** y el archivo **.env** dentro del directorio **"scripts"**

## Contenido 000-default.conf

~~~
ServerSignature Off
ServerTokens Prod

<VirtualHost *:80>
    #ServerName www.example.com
    DocumentRoot /var/www/html
    DirectoryIndex index.php index.html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    
    <Directory "/var/www/html/stats">
      AllowOverride All
    </Directory>
</VirtualHost>
~~~

**⚠️!!!IMPORTANTE¡¡¡⚠️**

Es importante el añadir las tres últimas líneas del archivo ya que estas nos permiten el tener los permisos suficientes para realizar cambios en nuestro wordpress.

## Contenido .htaccess

Configuración para los enlaces permanentes de WordPress.

~~~
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
~~~

## Contenido .env

Configuración de las variables

~~~
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wp_user
WORDPRESS_DB_PASSWORD=wp_pass
IP_CLIENTE_MYSQL=localhost  
WORDPRESS_DB_HOST=localhost

CERTIFICATE_MAIL=demo@demo.com
CERTIFICATE_DOMAIN=practicaiaw-https.ddns.net
~~~

## Contenido setup_letsencrypt_certificate.sh

Cuando realicemos los scripts de configuración y de de instalar la pila LAMP, realizaremos otro para realizar la instalación y configuración de **Certbot**.

~~~
!/bin/bash
~~~

~~~
set -x
~~~

### 1. Actualizamos los repositorio

~~~
apt update -y
~~~

### 2. Actualizamos los paquetes

~~~
apt upgrade -y
~~~

### 3. Importamos el archivo de variables .env

~~~
source .env
~~~

### 4. Instalamos y actualizamos snapd

~~~
snap install core
snap refresh core
~~~

### 5. Eliminamos cualuquier instalación previa de certbot con apt

~~~
apt remove certbot
~~~

### 6. Instalamos la aplicación certbot

~~~
snap install --classic certbot
~~~

### 7. Creamos un alias para la aplicación certbot

~~~
ln -sf /snap/bin/certbot /usr/bin/certbot
~~~

### 8. Ejecutamos el comando certbot

~~~
certbot --apache -m $CERTIFICATE_MAIL --agree-tos --no-eff-email -d $CERTIFICATE_DOMAIN --non-interactive
~~~


Ya realizado los archivos de configuración para el html y los enlaces permanentes,  realizaremos los scripts necesarios para la instalaciñon y configuración de **WP-CLI**.

## Instalación de WP-CLI  (deploy_wordpress_with_wpcli.sh).

~~~
!/bin/bash
~~~

~~~
set -x
~~~

### 1. Actualizamos los repositorio.

~~~
apt update -y
~~~

### 2. Actualizamos los paquetes.

~~~
apt upgrade -y
~~~

### 3. Importamos el archivo de variables .env.

~~~
source .env
~~~

### 4. Eliminamos descargas previas de wp-cli

~~~
rm -rf /tmp/wp-cli.phar
~~~

### 5. Descargamos la última versión de WP-CLI con el comando wget.

~~~
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp
~~~

### 6. Le asignamos los permisos de ejecución

~~~
chmod +x /tmp/wp-cli.phar
~~~

### 7. Movemos el archivo wp-cli.phar al directorio /usr/local/bin/ con el nombre wp

~~~
mv /tmp/wp-cli.phar /usr/local/bin/wp
~~~

### 8. Eliminamos instalaciones previas de WordPress

~~~
rm -rf /var/www/html/*
~~~

### 9. Descargamos el código fuete de WordPress en var/www/html

~~~
wp core download --locale=es_ES --path=/var/www/html --allow-root
~~~

### 10. Creamos base de datos y el usuario de la base de datos

~~~
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
~~~

### 11. Creamos el archivo wp-config

~~~
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --path=/var/www/html \
  --allow-root 
~~~

### 12.Instalamos WordPress

~~~
wp core install \
  --url=$CERTIFICATE_DOMAIN \
  --title="$WORDPRESS_TITLE" \
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASS \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html \
  --allow-root
~~~

### 13. Instalamos un theme

~~~
wp theme install sydney --activate --path=/var/www/html --allow-root
~~~

### 14. Instalamos varios plugins

~~~
wp plugin install wps-hide-login --activate --path=/var/www/html --allow-root
wp plugin install permalink-manager --activate --path=/var/www/html --allow-root
wp plugin install woocommerce --activate --path=/var/www/html --allow-root
~~~

### 15. Eliminamos los plugins inactivos

~~~
wp plugin delete $(wp plugin list --status=inactive --field=name)
~~~

### 16. Modificamos los propietarios de /var/www/html 

~~~
chown -R www-data:www-data /var/www/html/
~~~
