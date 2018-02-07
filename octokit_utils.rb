#!/usr/bin/env ruby

require 'octokit'

class OctokitUtils
  attr_accessor :client


  def initialize(access_token)
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(:access_token => "#{access_token}")
    client.user.login

    #possible to authenticated rateLimit of 30 (unauthenticated 10)
    #Exception Class: Octokit::TooManyRequests
    #g = RC::Github.new :access_token => "#{access_token}",
    #               :log_method => method(:puts)
    #p [g.me, g.get('users/godfat')]
    #p g.all('users/godfat/repos').size # get all repositories across all pages

  end

  def list_repos(organization, options)
    if not options[:repo_regex]
      regex = '.*'
    else
      regex = options[:repo_regex]
    end
    repos ||= client.organization_repositories(organization).collect {|org| org[:name] if org[:name] =~ /#{regex}/}
    # The collection leaves nil entries in for non-matches
    repos = repos.select {|repo| repo }
    return repos.sort.uniq
  end

  def list_branches(namespace,repository, options)
    ownerrepo ||= [namespace, repository].reject(&:empty?).join('/')
    branches ||= client.branches(ownerrepo).collect {|branch| branch[:name]}
    # The collection leaves nil entries in for non-matches
    branches = branches.select {|branch| branch }
    return branches.sort.uniq
  end

  def search_code(repo, query, options)
    begin
      results ||= client.search_code(query)
    rescue StandardError => e
      puts "Exception Class: #{ e.class.name }"
      puts "Exception Message: #{ e.message }"
      puts "Exception Backtrace: #{ e.backtrace }"
    end
    return results

  end

end

