#!/bin/bash

atd

# Check if PHP database config exists. If not, copy in the default config
if [ -f /config/config.php ]; then
  echo "Using existing PHP database config file."
  echo "/opt/observium/discovery.php -u" | at -M now + 1 minute
  echo "/usr/bin/mysql_upgrade -uroot" | at -M now + 1 minute
else
  echo "Loading PHP config from default."
  mkdir -p /config/databases
  cp /opt/observium/config.php.default /config/config.php
  chown nobody:users /config/config.php
  PW=$(pwgen -1snc 32)
  sed -i -e 's/PASSWORD/'$PW'/g' /config/config.php
  sed -i -e 's/USERNAME/observium/g' /config/config.php
fi

# if syslog config line is not already in config.php then add it
grep -qF 'enable_syslog' /config/config.php || echo "\$config['enable_syslog'] = 1;" >> /config/config.php

ln -s /config/config.php /opt/observium/config.php
chown nobody:users -R /opt/observium
chmod 755 -R /opt/observium

if [ -f /etc/container_environment/TZ ] ; then
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/7.4/cli/php.ini
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ $TZ#g" /etc/php/7.4/apache2/php.ini
else
  echo "Timezone not specified by environment variable"
  echo UTC > /etc/container_environment/TZ
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ UTC#g" /etc/php/7.4/cli/php.ini
  sed -i "s#\;date\.timezone\ \=#date\.timezone\ \=\ UTC#g" /etc/php/7.4/apache2/php.ini
fi
