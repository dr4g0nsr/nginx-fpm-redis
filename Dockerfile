FROM ubuntu:18.04

LABEL maintainer="Dragutin Cirkovic <dragonmen@gmail.com>"

# Define the ENV variable
ENV php_ver "7.3"
ENV php_conf /etc/php/${php_ver}/fpm/php.ini
ENV supervisor_conf /etc/supervisor/conf.d/supervisord.conf
ENV DEBIAN_FRONTEND=noninteractive

# Apt update and install all packages
RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN add-apt-repository ppa:ondrej/nginx
RUN apt-get update
RUN apt-get install -y curl wget gpg git nginx php${php_ver}-fpm php${php_ver}-cli supervisor tzdata curl sysstat \
certbot nano zip multitail unzip redis apache2-utils

RUN apt-get install -y curl php-common php${php_ver}-common php${php_ver}-json php${php_ver}-opcache php${php_ver}-readline \
php${php_ver}-mysqli php${php_ver}-memcached php${php_ver}-memcache php${php_ver}-redis php${php_ver}-gd php${php_ver}-xml \
php${php_ver}-curl php${php_ver}-apcu php${php_ver}-bcmath php${php_ver}-mongodb php${php_ver}-pgsql php${php_ver}-exif \
php${php_ver}-gmagick php${php_ver}-rrd php-sodium php${php_ver}-solr php-xhprof php${php_ver}-xdebug php-zip php-mbstring \
php-sqlite3

# Timezone config
RUN ln -fs /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Enable php-fpm on nginx virtualhost configuration
RUN rm /etc/nginx/sites-enabled/default
COPY conf/nginx-site.conf /etc/nginx/sites-enabled/default
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy all snippets
COPY conf/snippets/* /etc/nginx/snippets/

#COPY conf/snippets/error-pages.conf /etc/nginx/snippets/error-pages.conf
#COPY conf/snippets/php-fpm.conf /etc/nginx/snippets/php-fpm.conf
#COPY conf/snippets/static.conf /etc/nginx/snippets/static.conf
#COPY conf/snippets/wordpress.conf /etc/nginx/snippets/wordpress.conf

# Sock file potnt to /run/php/php-fpm.sock
RUN sed -i -e 's/listen = \/run\/php\/php7.3-fpm.sock/listen = \/run\/php\/php-fpm.sock/g' /etc/php/7.3/fpm/pool.d/www.conf

# Copy supervisor configuration
COPY conf/supervisord.conf ${supervisor_conf}

# Copy default redis
COPY conf/redis.conf /etc/redis.conf

# Default page with phpinfo
COPY src/* /var/www/html/

# Copy all errors
RUN mkdir /var/www/errors
COPY errors/* /var/www/errors/

# Copy executables
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-multitail.sh /docker-multitail.sh
COPY docker-healthcheck.sh /docker-healthcheck.sh

# Executable all .sh in root
RUN chmod 777 /*.sh

# www-data is owner of files
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /run/php

# Volume configuration
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

# Expose web and ssl ports
EXPOSE 80 443

CMD ["/docker-entrypoint.sh"]
