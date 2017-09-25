#!/usr/bin/env ruby
require 'net/http'
require 'uri'

VERSION = File.read('VERSION').strip
#RC_VERSION = File.read('VERSION').strip if File.read('RC').strip != ''
MAJOR=`cat VERSION | cut -d. -f1`.strip
MINOR=`cat VERSION | cut -d. -f2`.strip
RC_VERSION=`cat VERSION | cut -d- -f2`.strip
PROJECTS = %w(foreman foreman-proxy foreman-installer foreman-selinux)

`git clone git@github.com:dlobatog/foreman-packaging.git`
Dir.chdir('foreman-packaging')
`git remote add upstream git@github.com:theforeman/foreman-packaging.git`
`git fetch upstream`

################### RPM
`git checkout upstream/rpm/#{MAJOR}.#{MINOR}`
`git checkout -b rpm/#{MAJOR}.#{MINOR}`
`git pull --rebase upstream rpm/#{MAJOR}.#{MINOR}`
PROJECTS.each do |project|
  Dir.chdir("#{project}")
  if RC_VERSION
    `sed -i 's/.*global alphatag.*/%global alphatag' #{RC_VERSION}/g' #{project}.spec`
    `sed -i 's/.*global dotalphatag.*/%global dotalphatag .%{alphatag}/g' #{project}.spec`
    `sed -i 's/.*global dashalphatag.*/%global dashalphatag -%{alphatag}/g' #{project}.spec`
    `sed -i 's/^Release.*/Release: 0.1%{?dotalphatag}%{?dist}/g' #{project}.spec`
  else
    `sed -i 's/.*global alphatag.*/#global alphatag/g' #{project}.spec`
    `sed -i 's/.*global dotalphatag.*/#global dotalphatag .%{alphatag}/g' #{project}.spec`
    `sed -i 's/.*global dashalphatag.*/#global dashalphatag -%{alphatag}/g' #{project}.spec`
    `sed -i 's/^Release.*/Release: 1%{?dotalphatag}%{?dist}/g' #{project}.spec`
    `sed -i 's/^Version:.*/Version: #{VERSION}/g' #{project}.spec`
  end
  `spectool -g *.spec`
  `git rm  *.tar.bz2`
  `wget http://downloads.theforeman.org/#{project}/#{project}-#{VERSION}.tar.bz2`
  `git annex add *.tar.bz2`
  `git add .`
  Dir.chdir('../')
end

`git commit -m "Release #{VERSION}"`
# Rather submit PR?
`git push -f origin rpm/#{MAJOR}.#{MINOR}`
`git push upstream rpm/#{MAJOR}.#{MINOR}`

################### DEB

`git checkout upstream/deb/#{MAJOR}.#{MINOR}`
`git checkout -b deb/#{MAJOR}.#{MINOR}`
`git pull --rebase upstream deb/#{MAJOR}.#{MINOR}`
`scripts/changelog.rb -v #{VERSION}-1 -m "#{VERSION} released" debian/*/*/changelog`
`git add .`
`git commit -m "Core projects: Release #{VERSION}"`
# Rather submit PR?
`git push -f origin deb/#{MAJOR}.#{MINOR}`
`git push upstream deb/#{MAJOR}.#{MINOR}`

###
puts "Done with packaging! Make sure the PRs are able to build scratch builds properly, then 'tito tag' your new builds"
