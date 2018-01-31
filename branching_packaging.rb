#!/usr/bin/env ruby
require 'date'
require 'yaml'

config_path = './config.yml'

raise "No config.yml found, see config.yml.example for inspiration" unless File.exist?(config_path)
config = YAML.load_file(config_path)

github_user = config[:github_user]
raise "No github_user found in config.yml" unless github_user

push_upstream = config[:push_upstream] || false

deb_versions = config[:deb_versions]
raise "No deb_versions specified in config.yml" unless deb_versions

# VERSION = File.read('VERSION').strip
MAJOR=`cat VERSION | cut -d. -f1`.strip
MINOR=`cat VERSION | cut -d. -f2`.strip
NEXT = "#{MAJOR}.#{MINOR.to_i + 1}"
RELEASER = "#{`git config user.name`.strip} \<#{`git config user.email`.strip}\>"
DATE = Date.parse(Time.now.to_s).strftime('%a %b %d %Y')
PROJECTS = %w(foreman foreman-proxy foreman-installer foreman-selinux)

def current_release
  "#{MAJOR}.#{MINOR}"
end

def current_release_brach(os)
  "#{os}/#{current_release}"
end

def current_release_rpm_branch
  current_release_brach "rpm"
end

def current_release_deb_branch
  current_release_brach "deb"
end

def upstream_url
  if push_upstream
    "git@github.com:theforeman/foreman-packaging"
  else
    "https://github.com/theforeman/foreman-packaging.git"
  end
end

`git clone git@github.com:#{github_user}/foreman-packaging.git`
Dir.chdir('foreman-packaging')

`git remote add upstream #{upstream_url}`
`git fetch upstream`

################### RPM
# ============-=================== Version branch =====================-============
puts "Making changes for #{current_release_rpm_branch}"
`git checkout upstream/#{current_release_rpm_branch}`
`git checkout -b #{current_release_rpm_branch}`

`sed -i 's/nightly/#{current_release}/g' rel-eng/releasers.conf`
`sed -i 's/nightly/#{current_release}/g' rel-eng/tito.props`
`sed -i 's:nightly:releases/#{current_release}:g' foreman/foreman.repo`
`sed -i 's/nightly/#{current_release}/g' foreman/foreman.repo`
`sed -i 's/gpgcheck=0/gpgcheck=1/g' foreman/foreman.repo`
`sed -i 's:nightly:releases/#{current_release}:g' foreman/foreman-plugins.repo`
`sed -i 's/nightly/#{current_release}/g' foreman/foreman-plugins.repo`

`git add rel-eng/releasers.conf`
`git add rel-eng/tito.props`
`git commit -m "Update rel-eng to #{current_release}"`
`git add foreman/foreman.repo`
`git add foreman/foreman-plugins.repo`
`git commit -m "Update Foreman repo to #{current_release}"`

`git push origin #{current_release_rpm_branch}`
`git push upstream #{current_release_rpm_branch}` if push_upstream

puts "Manually substitute the GPG key in foreman/foreman.gpg by the one used in this release"

# ============-=================== Develop branch =====================-============

`git checkout upstream/rpm/develop`
`git checkout -b rpm/develop`

`git pull --rebase upstream rpm/develop`

PROJECTS.each do |project|
  `sed -i 's/^Version:.*/Version: #{NEXT}.0/g' #{project}/#{project}.spec`
  `sed -i '/%changelog/a \
* #{DATE} #{RELEASER} - #{NEXT}.0-0.develop\\n\
- Bump version to #{NEXT}-develop' #{project}/#{project}.spec`
  `git add #{project}/#{project}.spec`
end

`sed -i 's/fm#{MAJOR}_#{MINOR}/fm#{MAJOR}_#{MINOR.to_i + 1}/g' rel-eng/releasers.conf`
`sed -i 's/fm#{MAJOR}_#{MINOR}/fm#{MAJOR}_#{MINOR.to_i + 1}/g' rel-eng/tito.props`
`git add rel-eng/releasers.conf`
`git add rel-eng/tito.props`
`git commit -m "Update core projects to #{NEXT}"`
`git push origin rpm/develop`
`git push upstream rpm/develop` if push_upstream

################### DEBS
# Get changelogs from deb/VERSION-1
# ============-=================== Develop branch =====================-============
`git checkout upstream/deb/develop`
`git pull --rebase upstream deb/develop`
`git checkout --merge upstream/deb/#{MAJOR}.#{MINOR.to_i - 1} debian/{#{deb_versions}}/*/changelog`
`git commit -m "Sync #{MAJOR}.#{MINOR.to_i - 1}.x releases into changelogs"`
`git push origin deb/develop`
# Branch deb/VERSION
# ============-=================== Version branch =====================-============
`git checkout -b #{current_release_deb_branch}`
`git push origin #{current_release_deb_branch}`
# Update changelog to next version
# ============-=================== Develop branch =====================-============
`git checkout -b deb/develop`
`scripts/changelog.rb -v #{NEXT}.0-1 -m "Bump changelog to #{NEXT}.0 to match VERSION" debian/*/*/changelog`
`git add .`
`git commit -m "Bump changelog to #{NEXT}.0 to match VERSION"`
`git push origin deb/develop`
