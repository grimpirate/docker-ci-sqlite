# Base image
FROM alpine

# Configurable build time variables
ARG db_name=auth
ARG db_sessions=ci_sessions
ARG tz_country=America
ARG tz_city=New_York
ARG ci_subdir=sub
ARG ci_baseurl=http://localhost

# Install requirements for Codeigniter and SQLite
RUN apk add --no-cache nano tzdata sqlite composer apache2 php-apache2 php-intl php-ctype php-sqlite3 php-tokenizer php-session
RUN rm -rf /var/cache/apk/*

# Setup timezone (appropriate timezone necessary for Google 2FA)
RUN cp /usr/share/zoneinfo/$tz_country/$tz_city /etc/localtime
RUN echo "${tz_country}/${tz_city}" > /etc/timezone
RUN sed -i "s/;date.timezone =/date.timezone = \"${tz_country}\/${tz_city}\"/" /etc/php*/php.ini
RUN sed -i "s/memory_limit = 128M/memory_limit = 1024M/" /etc/php*/php.ini

# Fully qualified ServerName
RUN sed -i "s/#ServerName.*/ServerName 127.0.0.1/" /etc/apache2/httpd.conf
# Enable mod_rewrite in apache (for .htaccess to function correctly)
RUN sed -i "s/#LoadModule rewrite_module/LoadModule rewrite_module/" /etc/apache2/httpd.conf
# AllowOverride All for .htaccess directives to supercede defaults
RUN sed -i "s/AllowOverride None/AllowOverride All/" /etc/apache2/httpd.conf

# <CodeIgniter 4 Default Setup>

WORKDIR /var/www/localhost/htdocs

# Clear contents of htdocs
RUN rm -rf *

# Change htdocs folder group:user
RUN chown apache:apache /var/www/localhost/htdocs

# Change web folder from /var/www/localhost/htdocs to CodeIgniter public folder
RUN sed -i "s/htdocs/htdocs\/${ci_subdir}\/public/" /etc/apache2/httpd.conf

USER apache

# Create subdirectory
RUN mkdir $ci_subdir

# Composer install CodeIgniter 4 framework
RUN composer require codeigniter4/framework

# Copy files from framework into subdirectory
RUN cp -R vendor/codeigniter4/framework/app $ci_subdir/.
RUN cp -R vendor/codeigniter4/framework/public $ci_subdir/.

# Use writable at the framework level rather than subdirectory level
RUN cp -R vendor/codeigniter4/framework/writable .

# Copy spark and .env file into subdirectory (ignoring phpunit.xml.dist)
RUN cp vendor/codeigniter4/framework/env $ci_subdir/.env
RUN cp vendor/codeigniter4/framework/spark $ci_subdir/.

# Modify default app paths to be one level higher
RUN sed -i "s/\/..\/..\/system/\/..\/..\/..\/vendor\/codeigniter4\/framework\/system/" $ci_subdir/app/Config/Paths.php
RUN sed -i "s/\/..\/..\/writable/\/..\/..\/..\/writable/" $ci_subdir/app/Config/Paths.php
RUN sed -i "s/\/..\/..\/tests/\/..\/..\/..\/tests/" $ci_subdir/app/Config/Paths.php

# Modify composer path to be one level higher
RUN sed -i "s/vendor\/autoload.php/..\/vendor\/autoload.php/" $ci_subdir/app/Config/Constants.php

# Change environment to development
RUN sed -i "s/# CI_ENVIRONMENT = production/CI_ENVIRONMENT = development/" $ci_subdir/.env

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
RUN echo "docker.db_sessions=${db_sessions}">> $ci_subdir/.env
RUN echo "docker.tz_country=${tz_country}">> $ci_subdir/.env
RUN echo "docker.tz_city=${tz_city}">> $ci_subdir/.env
RUN echo "docker.ci_subdir=${ci_subdir}">> $ci_subdir/.env
RUN echo "docker.ci_baseurl=${ci_baseurl}">> $ci_subdir/.env

# Disable Session Handler info message (NOTE MODIFYING VENDOR DIRECTLY, THIS IS DANGEROUS)
RUN sed -i "s/\$this->logger->info/\/\/\$this->logger->info/" vendor/codeigniter4/framework/system/Session/Session.php
# Modify DatabaseHandler to function with SQLite3 (NOTE MODIFYING VENDOR DIRECTLY, THIS IS DANGEROUS)
RUN sed -i "s/'now()'/'CURRENT_TIMESTAMP'/g" vendor/codeigniter4/framework/system/Session/Handlers/DatabaseHandler.php
RUN sed -i "s/\"now() - INTERVAL {\$interval}\"/match (config(Database::class)->{\$this->DBGroup}['DBDriver']) {\n\t\t\t\t'SQLite3' => \"datetime('now', '-{\$max_lifetime} second')\",\n\t\t\t\tdefault   => \"now() - INTERVAL {\$max_lifetime} second\",\n\t\t\t}/" vendor/codeigniter4/framework/system/Session/Handlers/DatabaseHandler.php

# Copy our custom site logic
ADD --chown=apache:apache app $ci_subdir/app
# ADD --chown=apache:apache public $ci_subdir/public

# </Custom Site Setup>

# Create SQLite database(s)
RUN php $ci_subdir/spark db:create $db_name --ext db
RUN php $ci_subdir/spark db:create app --ext db

# Setup shield using spark and answer yes to migration question
RUN yes | php $ci_subdir/spark shield:setup

# Initial setup
RUN php $ci_subdir/spark setup:initial

# Post setup clean up
# RUN rm -rf $ci_subdir/app/Commands
# RUN rm -rf $ci_subdir/public/favicon.ico

USER root

# Set up volume into htdocs directory
VOLUME ["/var/www/localhost/htdocs"]

# Run configure.sh
ENTRYPOINT ["sh", "-c", "httpd -k start & tail -f /dev/null"]

# Expose port 80 for external access
EXPOSE 80
