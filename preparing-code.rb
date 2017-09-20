#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'

VERSION = File.read('VERSION').strip
RC_VERSION = File.read('RC_VERSION').strip
URL = 'http://projects.theforeman.org'

# Check out installer modules
# Compare packages in nightly vs release and retag dependencies

# Create new release via API call
# Create new search by open + release field

@current_release_id = 240
@next_release_id = 276

# Move bugs with Release set to VERSION to NEXT-VERSION with status new
def gather_issues
  url = "#{URL}/projects/foreman/issues.json?status_id=1&limit=100&release_id=#{@current_release_id}"
  puts url
  uri = URI(URI.escape(url))
  response = Net::HTTP.get(uri)
  JSON.parse(response)
end

def modify_target_version!(issue_id, options)
  uri = URI(URI.escape("#{URL}/issues/#{issue_id}.json"))
  req = Net::HTTP::Put.new(uri,
                           { 'Content-Type' => 'application/json',
                             'X-Redmine-API-Key' => File.read('~/.redminekey') })
  req.body = { :issue => { :release_id => options[:next_release] } }.to_json
  response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
  puts "#{response.code} - #{response.body} - when changing #{issue_id} target version to #{options[:next_release]}"
end

if !RC_VERSION # Only modify issues if it's a final version
  gather_issues['issues'].each do |issue|
    puts "#{issue['id']} - #{issue['subject']}"
    modify_target_version!(issue['id'], :next_release => @next_release_id)
  end
end

# Close the release
puts "Close the release http://projects.theforeman.org/rb/release/266/edit - not possible to do through the API"
