#!/usr/bin/env ruby

VERSION = File.read('VERSION').strip
require 'net/http'
%w(foreman foreman-proxy foreman-installer foreman-selinux).each do |project|
  File.write("#{project}-#{VERSION}.tar.bz2", Net::HTTP.get(URI.parse("http://downloads.theforeman.org/#{project}/#{project}-#{VERSION}.tar.bz2")))
  `gpg --homedir private_key -b -u packages@theforeman.org #{project}-#{VERSION}.tar.bz2`
  `scp #{project}-#{VERSION}.tar.bz2.sig dlobatog@theforeman.org:/var/www/vhosts/downloads/htdocs/#{project}/`
end
