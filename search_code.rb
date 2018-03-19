#!/usr/bin/env ruby
#This script is to output details of the repos seach to a csv file.

require 'csv'
require 'optparse'
require 'csv'
require 'octokit'
require 'rest-more'

require_relative 'octokit_utils'

options = {}
options[:oauth] = ENV['GITHUB_COMMUNITY_TOKEN'] if ENV['GITHUB_COMMUNITY_TOKEN']

parser = OptionParser.new do |opts|
  #default banner uses base filename, usually fine.
  #opts.banner = "Usage: #{__FILE__} [options]"
  opts.on('-s', '--search STRING', 'Search String. Required.') { |v| options[:search] = v }
  opts.on('-n', '--namespace NAME', 'GitHub namespace. Required.') { |v| options[:namespace] = v }
  opts.on('-t', '--oauth-token TOKEN', 'OAuth token. Required.') { |v| options[:oauth] = v }
  opts.on('-r', '--repo-regex REGEX', 'Repository regex') { |v| options[:repo_regex] = v }

  # default filters
  opts.on('--puppetlabs', 'Select Puppet Labs\' modules') {
    options[:namespace] = 'puppetlabs'
    options[:repo_regex] = '^puppetlabs-'
  }
  opts.on('--puppetlabs-supported', 'Select only Puppet Labs\' supported modules') {
    options[:namespace] = 'puppetlabs'
    options[:repo_regex] = OctokitUtils::SUPPORTED_MODULES_REGEX
  }
end

#slurp options
parser.parse!

missing = []
missing << '-s' if options[:search].nil?
missing << '-n' if options[:namespace].nil?
missing << '-t' if options[:oauth].nil?

if not missing.empty?
  puts
  puts "Missing options: #{missing.join(', ')}"
  puts
  puts parser
  exit
end

#default to 'All the Things'
options[:repo_regex] = '.*' if options[:repo_regex].nil?

#OctoKit object as util
util = OctokitUtils.new(options[:oauth])

#utilizing client.organization_repositories octokit method
#repos = [ 'puppetlabs-accounts', 'puppetlabs-modules']
repos = util.list_repos(options[:namespace], options)

if repos.empty?
  puts "Exiting #{__FILE__}: No repos found for ${options[:namespace]}"
  exit
else
  puts "\nTotal repos to process: #{repos.count}."
  repos.each_with_index do |r,r_index| #BEGIN repos loop
    #index begins with 0; so, add 1
    index_plus_one = r_index + 1

    if index_plus_one % 30 == 0
      puts "\nSleeping 61 seconds for 'github search rate-limit' of 30 requests/minute; https://developer.github.com/v3/search/#rate-limit"
      sleep(61)
    end

    #utilizing client.search_code octokit method
    query = "\"#{options[:search]}\" in:file repo:#{options[:namespace]}/#{r}"
    puts "\nProcessing Repo: #{r}, Query: #{query}"
    results ||= (util.search_code(r, query, options)).to_h
    items   ||= results[:items]

    #Looks like we can't specify the dang branch, only fork=true; Need to investigate
    #octokit/search_code restrictions, and blow right past them.
    #utilizing client.branches octokit method
    #branches = util.list_branches(options[:namespace],r, options)

    #Evaluate the results, is there anything to work with?
    if results.count < 3
      puts "\t...skipping #{r}: expecting 3 returned #{results.count}"
      next #Next repo
    elsif results[:incomplete_results] == "false"
      puts "\t...skipping #{r}: 'incomplete_results' for #{query}"
      next #Next repo
    elsif results[:total_count] == "0"
      puts "\t...skipping #{r}: 'total_count' is 0 for #{query}"
      next #Next repo
    elsif items.empty?
      puts "\t...skipping #{r}: no results found for #{query}"
      next #Next repo
    end

    #collect path,html_url,sha from results
    #Hash[results[:items].collect {|d| [d[:path], "#{d[:html_url]}, #{d[:sha]}"]}]

    #Create a csv file, for ease of use.
    CSV.open("results_#{options[:search]}.csv", "w") do |csv|
      csv << ["repo", "path", "url", "sha"]
      items.each do |i|
        csv << [r, i[:path], i[:html_url], i[:sha]]
      end

    end #END csv
  end #END repos loop
end # END repos.empty? loop

