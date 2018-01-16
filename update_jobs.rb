#!/usr/bin/env ruby
require 'yaml'

VERSION = File.read('VERSION').strip
MAJOR=`cat VERSION | cut -d. -f1`.strip
MINOR=`cat VERSION | cut -d. -f2`.strip
OLD_MINOR=(MINOR.to_i - 3).to_s

raise 'No config.yml present, see config.yml.example for an inspiration' unless File.exist?('config.yml')
config = YAML.load_file('./config.yml')

def github_user(config)
  config[:github_user] || raise("No :github_user in config.yml")
end

`git clone git@github.com:#{github_user(config)}/foreman-infra.git`
Dir.chdir('foreman-infra')
`git remote add upstream git@github.com:theforeman/foreman-infra.git`
`git fetch upstream`
`git pull --rebase upstream master`
`git checkout -b new-jobs-#{VERSION}`

JOBS = %w(
puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/packaging_build_deb_dependency.yaml
puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/packaging_build_deb_coreproject.yaml
puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/release_test.yaml
)

NEW_JOBS = {
"puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/test_#{MAJOR}_#{MINOR}_stable.yaml" => nil,
"puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/test_proxy_#{MAJOR}_#{MINOR}_stable.yaml" => nil
}

NEW_JOBS["puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/test_#{MAJOR}_#{MINOR}_stable.yaml"] = <<EOS
- job:
    name: test_#{MAJOR}_#{MINOR}_stable
    project-type: matrix
    logrotate:
      daysToKeep: -1
      numToKeep: 32
    quiet-period: 2700
    properties:
      - github_foreman
    scm:
      - foreman:
          branch: '#{MAJOR}.#{MINOR}-stable'
    triggers:
      - scm_fifteen_minutes
      - github
      - schedule_failed_builds
    axes:
      - axis:
          type: user-defined
          name: ruby
          values:
            - 2.1
            - 2.2
            - 2.3
            - 2.4
      - axis:
          type: user-defined
          name: database
          values:
            - postgresql
            - mysql
            - sqlite3
      - axis:
          type: label-expression
          name: slave
          values:
            - fast
    builders:
      - test_develop
    publishers:
      - gemset_cleanup
      - ircbot_freenode
      - archive:
          artifacts: 'pkg/*,Gemfile.lock'
          only-if-success: false
      - junit:
          results: 'jenkins/reports/unit/*.xml'
EOS

NEW_JOBS["puppet/modules/jenkins_job_builder/files/theforeman.org/yaml/jobs/test_proxy_#{MAJOR}_#{MINOR}_stable.yaml"] = <<EOS
- job:
    name: test_proxy_#{MAJOR}_#{MINOR}_stable
    project-type: matrix
    logrotate:
      daysToKeep: -1
      numToKeep: 16
    properties:
      - github:
          url: https://github.com/theforeman/smart-proxy
    scm:
      - foreman-proxy:
          branch: '#{MAJOR}.#{MINOR}-stable'
    triggers:
      - scm_fifteen_minutes
      - github
      - schedule_failed_builds
    axes:
      - axis:
          type: user-defined
          name: ruby
          values:
          - 2.1
          - 2.2
          - 2.3
          - 2.4
      - axis:
          type: user-defined
          name: puppet
          values:
          - 3.4.0
          - 3.8.0
          - 4.2.0
          - 4.4.0
    execution-strategy:
      combination-filter: '!( (ruby ==~ /2\\.[^0]*/ && puppet ==~ /3\\.[0-4].*/) || (ruby ==~ /2\\.[2-9].*/ && puppet ==~ /3.*/) || (ruby ==~ /2\\.[3-9].*/ && puppet ==~ /4\\.[0-3].*/) )'
    builders:
      - test_proxy
    publishers:
      - gemset_cleanup
      - ircbot_freenode
      - junit:
          results: 'jenkins/reports/unit/*.xml'
      - archive:
          artifacts: 'pkg/*'
          only-if-success: true
EOS

NEW_JOBS.each do |job_path, content|
  File.open(job_path, 'w') { |file| file.write(content) }
  puts "Created new job - #{job_path}"
end

JOBS.each do |job_path|
  job = YAML.load(File.read(job_path))
  job[0]["job"]["axes"].first["axis"]["values"].delete("#{MAJOR}.#{OLD_MINOR}")
  job[0]["job"]["axes"].first["axis"]["values"] << "#{MAJOR}.#{MINOR}"
  File.open(job_path, 'w') { |file| file.write(job.to_yaml) }

  puts "Updated job - #{job_path}"
end
