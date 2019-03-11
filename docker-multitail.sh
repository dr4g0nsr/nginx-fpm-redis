#!/bin/bash

# 2 columns show of multitail
/usr/bin/multitail -s 2 /var/log/nginx/access.log  /var/log/nginx/error.log /var/log/php-fpm.log /tmp/supervisord.log
