#!/usr/bin/env ruby
require 'smarter_csv'

class ReleaseIssues
  def initialize
    raise 'No issues.csv found' unless File.exist?('./issues.csv')
    @csv = ::SmarterCSV.process('./issues.csv')
  end

  def run
    groups = @csv.group_by { |hash| hash[:category] }
    # handle issues without categoory
    groups['Uncategorized'] = groups.delete(nil)
    File.open('issues_out.md', 'w+') do |file|
      print_issues file, groups.sort.to_h
    end
  end

  def category_header(item)
    "#### #{item}"
  end

  def issue_line(hash)
    "* #{hash[:subject]} (#{issue_link hash})"
  end

  def issue_link(hash)
    "[##{hash[:id]}](http://projects.theforeman.org/issues/#{hash[:id]})"
  end

  def print_section(file, group_key, group_val)
    file.puts(category_header group_key)
    group_val.each do |issue_hash|
      file.puts issue_line(issue_hash)
    end
    file.puts
  end

  def print_issues(file, groups)
    groups.each do |group_key, group_val|
      print_section file, group_key, group_val
    end
  end
end

ReleaseIssues.new.run
