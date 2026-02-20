# Base image
FROM alpine

# Configurable build time variables
ARG db_name=auth
ARG tz_country=America
ARG tz_city=New_York
ARG ci_subdir=sub
ARG ci_baseurl=http://localhost
ARG ci_environment=development

# Install requirements for Codeigniter and SQLite
RUN apk add --no-cache nano tzdata sqlite composer nginx php php-fpm php-intl php-ctype php-sqlite3 php-tokenizer php-session
# Needed for grimpirate/halberd package
RUN apk add php-xmlwriter
# Clear Alpine package cache
RUN rm -rf /var/cache/apk/*

# Setup timezone (appropriate timezone necessary for Google 2FA)
RUN cp /usr/share/zoneinfo/$tz_country/$tz_city /etc/localtime
RUN echo "${tz_country}/${tz_city}" > /etc/timezone
RUN sed -i "s/;date.timezone =/date.timezone = \"${tz_country}\/${tz_city}\"/" /etc/php*/php.ini
# Increase PHP memory limit
RUN sed -i "s/memory_limit = 128M/memory_limit = 1024M/" /etc/php*/php.ini

# <CodeIgniter 4 Default Setup>

WORKDIR /var/www/localhost/htdocs

# Clear contents of htdocs
RUN rm -rf *

# Change htdocs folder group:user
RUN chown nginx:nginx /var/www/localhost/htdocs

# Change web folder from /var/www/localhost/htdocs to CodeIgniter public folder
ADD default.conf /etc/nginx/http.d/default.conf

USER nginx

# Create subdirectories
RUN mkdir -p $ci_subdir/modules
RUN mkdir -p $ci_subdir/app/Config
RUN mkdir -p $ci_subdir/public

# Composer install CodeIgniter 4 framework
RUN composer require codeigniter4/framework

### MODIFYING VENDOR FILES DIRECTLY IS DANGEROUS!!! ###

# Disable Session Handler info message
RUN sed -i "s/\$this->logger->info/\/\/\$this->logger->info/" vendor/codeigniter4/framework/system/Session/Session.php
# Modify DatabaseHandler to use CURRENT_TIMESTAMP instead of now()
# RUN sed -i "s/'now()'/'CURRENT_TIMESTAMP'/g" vendor/codeigniter4/framework/system/Session/Handlers/DatabaseHandler.php
# Modify DatabaseHandler to provide for SQLite timestamp calculations for session garbage collection
# RUN sed -i "s/\"now() - INTERVAL {\$interval}\"/match (config(Database::class)->{\$this->DBGroup}['DBDriver']) {\n                'SQLite3' => \"datetime('now', '-{\$max_lifetime} second')\",\n                default   => \"now() - INTERVAL {\$max_lifetime} second\",\n            }/" vendor/codeigniter4/framework/system/Session/Handlers/DatabaseHandler.php

### MODIFYING VENDOR FILES DIRECTLY IS DANGEROUS!!! ###

# Copy files from framework into subdirectory
RUN cp -R vendor/codeigniter4/framework/app/Config/Autoload.php $ci_subdir/app/Config/.
RUN cp -R vendor/codeigniter4/framework/app/Config/Constants.php $ci_subdir/app/Config/.
RUN cp -R vendor/codeigniter4/framework/app/Config/Paths.php $ci_subdir/app/Config/.
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
# ADD --chown=nginx:nginx app $ci_subdir/app
# ADD --chown=nginx:nginx public $ci_subdir/public

# Create SQLite database(s)
RUN php $ci_subdir/spark db:create $db_name --ext db

# Setup shield using spark and answer yes to migration question
RUN yes | php $ci_subdir/spark shield:setup

# Post setup clean up
RUN rm -rf $ci_subdir/public/favicon.ico

RUN chmod -R 0777 /var/www/localhost/htdocs/writable

# </Custom Site Setup>

USER root

# Set up volume into htdocs directory
VOLUME ["/var/www/localhost/htdocs"]

# Run configure.sh
ENTRYPOINT ["sh", "-c", "php-fpm83 & nginx -g 'daemon off;'"]

# Expose port 80 for external access
EXPOSE 80
