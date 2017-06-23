#!/usr/bin/env ruby

VERSION = File.read('VERSION').strip
RC_VERSION = File.read('VERSION').strip if File.read('RC').strip != ''
PROJECTS = %w(foreman foreman-proxy foreman-installer foreman-selinux)

`git clone theforeman/foreman-packaging`
Dir.chdir('foreman-packaging')

################### RPM
`git checkout rpm/#{VERSION}`
PROJECTS.each do |project|
  Dir.chdir("#{project}")
  if RC_VERSION
    `sed -i s/.*global alphatag.*/%global alphatag #{RC_VERSION}/g #{project}.spec`
    `sed -i s/.*global dotalphatag.*/%global dotalphatag .%{alphatag}/g #{project}.spec`
    `sed -i s/.*global dashalphatag.*/%global dashalphatag -%{alphatag}/g #{project}.spec`
    `sed -i s/.*Release.*/Release: 0.1%{?dotalphatag}%{?dist}/g #{project}.spec`
  else
    `sed -i s/.*global alphatag.*/#%global alphatag/g #{project}.spec`
    `sed -i s/.*global dotalphatag.*/#%global dotalphatag .%{alphatag}/g #{project}.spec`
    `sed -i s/.*global dashalphatag.*/#%global dashalphatag -%{alphatag}/g #{project}.spec`
    `sed -i s/.*Release.*/Release: 1%{?dotalphatag}%{?dist}/g #{project}.spec`
    `sed -i s/Version:.*/Version: #{VERSION}/g #{project}.spec`
  end
  `spectool -g *.spec`
  File.write(
    "#{project}-#{VERSION}.tar.bz2",
    Net::HTTP.get(
      URI.parse("http://downloads.theforeman.org/#{project}/#{project}-#{VERSION}.tar.bz2")
    )
  )
  `git annex add *.tar.bz2`
  `git add .`
  Dir.chdir('../')
end

`git commit -m "Release #{VERSION}"`
# Rather submit PR?
`git push origin rpm/#{VERSION}`

################### DEB

`git checkout deb/#{VERSION}`
`scripts/changelog.rb -v #{VERSION}-1 -m "#{VERSION} released" debian/*/*/changelog`
`git add .`
`git commit -m "Core projects: Release #{VERSION}"`
# Rather submit PR?
`git push deb/#{VERISON}`

###
puts "Done with packaging! Make sure the PRs are able to build scratch builds properly, then 'tito tag' your new builds"
