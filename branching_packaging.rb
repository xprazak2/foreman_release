#!/usr/bin/env ruby
require 'date'

VERSION = File.read('VERSION').strip
MAJOR=`cat VERSION | cut -d. -f1`.strip
MINOR=`cat VERSION | cut -d. -f2`.strip
NEXT = "#{MAJOR}.#{MINOR.to_i + 1}"
RELEASER = "#{`git config user.name`.strip} \<#{`git config user.email`.strip}\>"
DATE = Date.parse(Time.now.to_s).strftime('%a %b %d %Y')
RC_VERSION = nil
PROJECTS = %w(foreman foreman-proxy foreman-installer foreman-selinux)

`git clone git@github.com:dlobatog/foreman-packaging.git`
Dir.chdir('foreman-packaging')
`git remote add upstream git@github.com:theforeman/foreman-packaging.git`
`git fetch upstream`

################### RPM
# ============-=================== Version branch =====================-============
`git checkout upstream/rpm/#{MAJOR}.#{MINOR}`
`git checkout -b rpm/#{MAJOR}.#{MINOR}`
`git pull --rebase upstream rpm/#{MAJOR}.#{MINOR}`

`sed -i 's/nightly/#{MAJOR}.#{MINOR}/g' rel-eng/releasers.conf`
`sed -i 's/nightly/#{MAJOR}.#{MINOR}/g' rel-eng/tito.props`
`sed -i 's/\\/nightly/releases\\/#{MAJOR}.#{MINOR}/g' foreman/foreman.repo`
`sed -i 's/nightly/#{MAJOR}.#{MINOR}/g' foreman/foreman.repo`
`sed -i 's/gpgcheck=0/gpgcheck=1/g' foreman/foreman.repo`
`sed -i 's/\\/nightly/\\/releases\\/#{MAJOR}.#{MINOR}/g' foreman/foreman-plugins.repo`
`sed -i 's/nightly/#{MAJOR}.#{MINOR}/g' foreman/foreman-plugins.repo`

`git add rel-eng/releasers.conf`
`git add rel-eng/tito.props`
`git commit -m "Update rel-eng to #{MAJOR}.#{MINOR}"`

`git add foreman/foreman.repo`
`git add foreman/foreman-plugins.repo`
`git commit -m "Update Foreman repo to #{MAJOR}.#{MINOR}"`

`git push origin rpm/#{MAJOR}.#{MINOR}`
`git push upstream rpm/#{MAJOR}.#{MINOR}`

puts "Manually substitute the GPG key in foreman/foreman.gpg by the one used in this release"

# ============-=================== Develop branch =====================-============

`git checkout rpm/develop`
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
`git push upstream rpm/develop`
