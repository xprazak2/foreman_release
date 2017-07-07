#!/bin/sh

sudo semanage fcontext -a -t public_content_t /var/www/vhosts/downloads/htdocs/foreman/foreman-1.15.2.tar.bz2.sig
sudo semanage fcontext -a -t public_content_t /var/www/vhosts/downloads/htdocs/foreman-proxy/foreman-proxy-1.15.2.tar.bz2.sig
sudo semanage fcontext -a -t public_content_t /var/www/vhosts/downloads/htdocs/foreman-installer/foreman-installer-1.15.2.tar.bz2.sig
sudo semanage fcontext -a -t public_content_t /var/www/vhosts/downloads/htdocs/foreman-selinux/foreman-selinux-1.15.2.tar.bz2.sig
sudo restorecon -v /var/www/vhosts/downloads/htdocs/foreman/foreman-1.15.2.tar.bz2.sig
sudo restorecon -v /var/www/vhosts/downloads/htdocs/foreman-proxy/foreman-proxy-1.15.2.tar.bz2.sig
sudo restorecon -v /var/www/vhosts/downloads/htdocs/foreman-installer/foreman-installer-1.15.2.tar.bz2.sig
sudo restorecon -v /var/www/vhosts/downloads/htdocs/foreman-selinux/foreman-selinux-1.15.2.tar.bz2.sig
