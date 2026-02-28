# Base image
FROM alpine

# Configurable build time variables
ARG user=apache
ARG db_name=auth
ARG tz_country=America
ARG tz_city=New_York
ARG ci_subdir=sub
ARG ci_baseurl=http://localhost
ARG ci_environment=development

# Install requirements for Codeigniter and SQLite
RUN apk add --no-cache nano tzdata sqlite composer php-intl php-ctype php-sqlite3 php-tokenizer php-session
# Needed for grimpirate/halberd package
RUN apk add php-xmlwriter
RUN\
	if [ "${user}" == "apache" ]; then \
		apk add --no-cache apache2 php-apache2; \
	else \
		apk add --no-cache nginx php php-fpm; \
	fi

# Clear Alpine package cache
RUN rm -rf /var/cache/apk/*

# Setup timezone (appropriate timezone necessary for Google 2FA)
RUN cp /usr/share/zoneinfo/$tz_country/$tz_city /etc/localtime
RUN echo "${tz_country}/${tz_city}" > /etc/timezone
RUN sed -i "s/;date.timezone =/date.timezone = \"${tz_country}\/${tz_city}\"/" /etc/php*/php.ini
# Increase PHP memory limit
RUN sed -i "s/memory_limit = 128M/memory_limit = 1024M/" /etc/php*/php.ini

RUN\
	if [ "${user}" == "apache" ]; then \
# Fully qualified ServerName
		sed -i "s/#ServerName.*/ServerName 127.0.0.1/" /etc/apache2/httpd.conf; \
# Enable mod_rewrite in apache (for .htaccess to function correctly)
		sed -i "s/#LoadModule rewrite_module/LoadModule rewrite_module/" /etc/apache2/httpd.conf; \
# AllowOverride All for .htaccess directives to supercede defaults
		sed -i "s/AllowOverride None/AllowOverride All/" /etc/apache2/httpd.conf; \
	fi

# <CodeIgniter 4 Default Setup>

WORKDIR /var/www/localhost/htdocs

# Clear contents of htdocs
RUN rm -rf *

# Change htdocs folder group:user
RUN chown $user:$user /var/www/localhost/htdocs

# Change web folder from /var/www/localhost/htdocs to CodeIgniter public folder
RUN\
	if [ "${user}" == "apache" ]; then \
		sed -i "s/htdocs/htdocs\/${ci_subdir}\/public/" /etc/apache2/httpd.conf; \
	else \
		mkdir -p /etc/nginx/http.d; \
	fi
ADD nginx/default.conf /etc/nginx/http.d/default.conf

USER $user

# Create subdirectories
RUN mkdir -p $ci_subdir/modules
RUN mkdir -p $ci_subdir/app/Config
RUN mkdir -p $ci_subdir/public

# Composer install CodeIgniter 4 framework
RUN composer require codeigniter4/framework

### MODIFYING VENDOR FILES DIRECTLY IS DANGEROUS!!! ###

# Disable Session Handler info message
# RUN sed -i "s/\$this->logger->info/\/\/\$this->logger->info/" vendor/codeigniter4/framework/system/Session/Session.php
# Modify DatabaseHandler to use CURRENT_TIMESTAMP instead of now()
# RUN sed -i "s/'now()'/'CURRENT_TIMESTAMP'/g" vendor/codeigniter4/framework/system/Session/Handlers/DatabaseHandler.php
# Modify DatabaseHandler to provide for SQLite timestamp calculations for session garbage collection
# RUN sed -i "s/\"now() - INTERVAL {\$interval}\"/match (config(Database::class)->{\$this->DBGroup}['DBDriver']) {\n                'SQLite3' => \"datetime('now', '-{\$max_lifetime} second')\",\n                default   => \"now() - INTERVAL {\$max_lifetime} second\",\n            }/" vendor/codeigniter4/framework/system/Session/Handlers/DatabaseHandler.php

### MODIFYING VENDOR FILES DIRECTLY IS DANGEROUS!!! ###

# Copy files from framework into subdirectory
RUN cp -R vendor/codeigniter4/framework/app/Config/Autoload.php $ci_subdir/app/Config/.
RUN cp -R vendor/codeigniter4/framework/app/Config/Constants.php $ci_subdir/app/Config/.
RUN cp -R vendor/codeigniter4/framework/app/Config/Paths.php $ci_subdir/app/Config/.
RUN echo -e "<?php\n\n" > $ci_subdir/app/Config/Routes.php
RUN cp -R vendor/codeigniter4/framework/app/Controllers $ci_subdir/app/
RUN cp -R vendor/codeigniter4/framework/public/index.php $ci_subdir/public/.

# Symlink framework app/ files
WORKDIR /var/www/localhost/htdocs/$ci_subdir/app
RUN find /var/www/localhost/htdocs/vendor/codeigniter4/framework/app/ -mindepth 1 -maxdepth 1 -exec ln -s "{}" . ';'

# Symlink framework app/Config/ files
WORKDIR /var/www/localhost/htdocs/$ci_subdir/app/Config
RUN find /var/www/localhost/htdocs/vendor/codeigniter4/framework/app/Config/ -mindepth 1 -maxdepth 1 -exec ln -s "{}" . ';'

# Symlink framework public/ files
WORKDIR /var/www/localhost/htdocs/$ci_subdir/public
RUN find /var/www/localhost/htdocs/vendor/codeigniter4/framework/public/ -mindepth 1 -maxdepth 1 -exec ln -s "{}" . ';'

WORKDIR /var/www/localhost/htdocs

# Shift .htaccess and index.html from app
RUN mv $ci_subdir/app/.htaccess $ci_subdir/app/index.html $ci_subdir

# Use writable at the framework level rather than subdirectory level
RUN cp -R vendor/codeigniter4/framework/writable .

# Copy spark and .env file into subdirectory (ignoring phpunit.xml.dist)
RUN cp vendor/codeigniter4/framework/env $ci_subdir/.env
RUN cp vendor/codeigniter4/framework/spark $ci_subdir/.

# Modify default app paths to be one level higher
RUN sed -i "s/\/..\/..\/system/\/..\/..\/..\/vendor\/codeigniter4\/framework\/system/" $ci_subdir/app/Config/Paths.php
RUN sed -i "s/\/..\/..\/writable/\/..\/..\/..\/writable/" $ci_subdir/app/Config/Paths.php

# Modify composer path to be one level higher
RUN sed -i "s/vendor\/autoload.php/..\/vendor\/autoload.php/" $ci_subdir/app/Config/Constants.php

# Modify Autoload with Master module namespace
RUN sed -i "s/APP_NAMESPACE => APPPATH,/APP_NAMESPACE => APPPATH,\n\t\t'Modules\\\\Master' => ROOTPATH . 'modules\/Master',/" $ci_subdir/app/Config/Autoload.php

# Change environment to development
RUN sed -i "s/# CI_ENVIRONMENT = production/CI_ENVIRONMENT = ${ci_environment}/" $ci_subdir/.env

# Set project minimum-stability to dev
RUN composer config minimum-stability dev
RUN composer config prefer-stable true

# Composer install shield (for user administration)
RUN composer require codeigniter4/shield:dev-develop

# </CodeIgniter 4 Default Setup>

# <Custom Site Setup>

# RUN composer require guzzlehttp/guzzle

# Copy all environment variables to .env file
RUN echo "docker.db_name=${db_name}.db">> $ci_subdir/.env
RUN echo "docker.tz_country=${tz_country}">> $ci_subdir/.env
RUN echo "docker.tz_city=${tz_city}">> $ci_subdir/.env
RUN echo "docker.ci_subdir=${ci_subdir}">> $ci_subdir/.env
RUN echo "docker.ci_baseurl=${ci_baseurl}">> $ci_subdir/.env

# Copy our custom site logic
ADD --chown=$user:$user modules $ci_subdir/modules
RUN cp -R vendor/codeigniter4/framework/app/Views $ci_subdir/modules/Master
# ADD --chown=$user:$user app $ci_subdir/app
# ADD --chown=$user:$user public $ci_subdir/public

# Create SQLite database(s)
RUN php $ci_subdir/spark db:create $db_name --ext db

# Setup shield using spark and answer yes to migration question
RUN yes | php $ci_subdir/spark shield:setup

# Post setup clean up
RUN rm -rf $ci_subdir/public/favicon.ico
RUN rm -rf $ci_subdir/app/Controllers/Home.php
RUN rm -rf $ci_subdir/app/Database
RUN rm -rf $ci_subdir/app/Filters
RUN rm -rf $ci_subdir/app/Helpers
RUN rm -rf $ci_subdir/app/Language
RUN rm -rf $ci_subdir/app/Libraries
RUN rm -rf $ci_subdir/app/Models
RUN rm -rf $ci_subdir/app/ThirdParty
RUN rm -rf $ci_subdir/app/Views

RUN\
	if [ "${user}" == "nginx" ]; then \
		chmod -R 0777 /var/www/localhost/htdocs/writable; \
	fi

# </Custom Site Setup>

USER root

# Set up volume into htdocs directory
VOLUME ["/var/www/localhost/htdocs"]

ENV GRIMUSER=$user

# Run configure.sh
ENTRYPOINT ["sh", "-c", "if [ \"$GRIMUSER\" == 'apache' ]; then httpd -k start & tail -f /dev/null; else php-fpm83 & nginx -g 'daemon off;'; fi"]

# Expose port 80 for external access
EXPOSE 80
