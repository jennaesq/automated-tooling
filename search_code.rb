#!/usr/bin/env ruby
#This script is to output details of the repos seach to a csv file.

require 'csv'
require 'optparse'
require 'csv'
require 'octokit'
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
#repos = util.list_repos(options[:namespace], options)
#repos.each do |r|
#  puts "repos----> #{r}"
#end

search_results = []

repos = [ 'puppetlabs-accounts', 'puppetlabs-modules']

if repos.empty?
  puts "Exiting #{__FILE__}: No repos found for ${options[:namespace]}"
  exit
else
  repos.each do |r| #BEGIN repos loop
    #utilizing client.search_code octokit method
    query = "#{options[:search]} in:file repo:#{options[:namespace]}/#{r}"
    #HELP ME!  Hash works for the first level, not seeming to work for lower levels.
    results = util.search_code(r, query, options)
    puts "Repo: #{r}, Query: #{query}"

    #Looks like we can't specify the damn branch, only fork=true; Lesson learned $#^@!
    #utilizing client.branches octokit method
    #branches = util.list_branches(options[:namespace],r, options)
    #branches.each do |b|
    #  puts "branches------> #{b}"
    #end

    #Are the results good, is there anything to work with?
    if results.count < 3
      puts "Skipping #{r}: expecting 3 returned #{results.count}"
      next #Next repo
    elsif results[:incomplete_results] == "false"
      puts "Skipping #{r}: 'incomplete_results' for #{query}"
      next #Next repo
    elsif results[:total_count] == "0"
      puts "Skipping #{r}: 'total_count' is 0 for #{query}"
      next #Next repo
    elsif results[:items].empty?
      puts "Skipping #{r}: no results found for #{query}"
      next #Next repo
    end

    #collect path from results
    #HELP ME! Collect works.  How would this line return or build a hash, if results isn't a hash?
    details  ||= results[:items].collect {|d| "#{d[:path]}, #{d[:html_url]}, #{d[:sha]}" }

    if details.empty?
      puts "no 'path' results found for #{query}"
      next #Next repo
    else
      #Process the details (paths, in this case)
      details.each do |path,url,sha|
        row = {"repo" => r, "path" => path, "url" => url, "sha" => sha}
        search_results.push(row)
        #HELP ME!  This fine example sucks because it has only populated r and path.
        #(Refer to HELP ME, line 100-ish)
        puts "ROW: #{r},#{path},#{url},#{sha}"
      end
    end #END details empty? loop


    #Create a csv file, for ease of use.
    CSV.open("search_code_#{options[:search]}.csv", "w") do |csv|
      csv << ["repo", "path", "url", "sha"]
      search_results.each do |s|
        csv << [s["repo"], s["path"], s["url"], s["sha"]]
      end

    end #END csv

  end #END repos loop
end # END repos.empty? loop


