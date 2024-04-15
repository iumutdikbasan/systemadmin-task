# Ortak işlemler
kartaca_user_creation:
  user.present:
    - name: kartaca
    - uid: 2024
    - gid: 2024
    - home: /home/krt
    - shell: /bin/bash
    - password: {{ salt['pillar.get']('user_password:kartaca') }}
    - createhome: True

kartaca_user_sudo:
  file.append:
    - name: /etc/sudoers
    - text: 'kartaca ALL=(ALL) NOPASSWD: /usr/bin/apt'  # Ubuntu için
    - text: 'kartaca ALL=(ALL) NOPASSWD: /usr/bin/yum'  # CentOS için

set_timezone:
  timezone.system:
    - name: Istanbul

enable_ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1

install_required_packages:
  pkg.installed:
    - pkgs:
      - htop
      - tcptraceroute
      - iputils-ping
      - dnsutils
      - sysstat
      - mtr

add_hashicorp_repo_and_install_terraform:
  cmd.run:
    - name: |
        curl -fsSL {{ pillar['hashicorp_repo_url'] }} | sudo bash -
        sudo apt update && sudo apt install terraform={{ pillar['terraform_version'] }}-1 -y  # Ubuntu için
        sudo yum install terraform-{{ pillar['terraform_version'] }} -y  # CentOS için

add_hosts_entries:
  file.append:
    - name: /etc/hosts
    - text: '{{ item.ip }}    {{ item.hostname }}'
    {% for item in pillar['hosts_entries'] %}
    - context:
        item: {{ item }}
    {% endfor %}

{% if grains['os'] == 'CentOS' %}
# CentOS özel işlemler
install_nginx:
  pkg.installed:
    - name: nginx

nginx_service_enable:
  service.running:
    - name: nginx
    - enable: True

install_php_and_configure_nginx:
  pkg.installed:
    - names:
      - php-fpm
      - php-mysqlnd
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://files/nginx.conf

download_and_extract_wordpress:
  cmd.run:
    - name: wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz && tar -xzf /tmp/wordpress.tar.gz -C /var/www/wordpress2024

configure_nginx_for_wordpress:
  file.managed:
    - name: /etc/nginx/sites-available/default
    - source: salt://files/nginx_wordpress.conf

configure_wp_config:
  file.managed:
    - name: /var/www/wordpress2024/wp-config.php
    - source: salt://files/wp-config.php
    - template: jinja

generate_wordpress_keys:
  cmd.run:
    - name: curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/wordpress2024/wp-config.php

generate_self_signed_ssl:
  cmd.run:
    - name: openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt

manage_nginx_with_salt:
  file.copy:
    - name: salt://files/nginx.conf
    - dest: /etc/nginx/nginx.conf

nginx_rotate_logs:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://files/nginx.logrotate

centos_nginx_cron_restart:
  cron.present:
    - name: Restart Nginx
    - user: root
    - minute: 0
    - hour: 0
    - daymonth: '*'
    - month: '*'
    - weekday: 1
    - job: systemctl restart nginx

{% endif %}

{% if grains['os'] == 'Ubuntu' %}
# Ubuntu özel işlemler
install_mysql:
  pkg.installed:
    - name: mysql-server

mysql_service_enable:
  service.running:
    - name: mysql
    - enable: True

create_mysql_database_and_user:
  mysql_database.present:
    - name: {{ pillar['mysql']['database'] }}
  mysql_user.present:
    - name: {{ pillar['mysql']['user'] }}
    - password: {{ pillar['mysql']['password'] }}
    - host: localhost
    - grant:
      - ALL

create_mysql_backup_cron:
  cron.present:
    - name: Backup MySQL Database
    - user: root
    - minute: 0
    - hour: 2
    - daymonth: '*'
    - month: '*'
    - weekday: '*'
    - job: mysqldump -u {{ pillar['mysql']['user'] }} -p'{{ pillar['mysql']['password'] }}' {{ pillar['mysql']['database'] }} > /backup/{{ pillar['mysql']['database'] }}_$(date +\%Y\%m\%d).sql
{% endif %}

