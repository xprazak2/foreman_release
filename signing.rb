#!/usr/bin/env ruby

require 'yaml'
require 'net/http'

config_path = './config.yml'

raise "No config.yml found, see config.yml.example for inspiration" unless File.exist?(config_path)
config = YAML.load_file(config_path)

theforeman_user = config[:theforeman_user]
raise "No theforeman_user found in config.yml" unless theforeman_user

gpg_homedir = config[:gpg_homedir]
raise "No gpg_homedir found in config.yml" unless gpg_homedir

projects = %w(foreman foreman-proxy foreman-installer foreman-selinux)

VERSION = File.read('VERSION').strip

restart gpg agent to make sure it is available
`sudo pkill -9 gpg-agent`
`gpg-agent --homedir="#{gpg_homedir}" --daemon`

puts "Downloading packages and signing them for #{VERSION} release"

projects.each do |project|
  File.write("#{project}-#{VERSION}.tar.bz2", Net::HTTP.get(URI.parse("http://downloads.theforeman.org/#{project}/#{project}-#{VERSION}.tar.bz2")))
  `gpg --homedir #{gpg_homedir} -b -u packages@theforeman.org #{project}-#{VERSION}.tar.bz2`
end

puts "Uploading signatures to theforeman.org"

puts `ansible-playbook -u #{theforeman_user} -K ./signing.yml -i 'theforeman.org,' --extra-vars='{"projects": #{projects}, "version": #{VERSION}}'`
