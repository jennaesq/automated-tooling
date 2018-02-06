#!/usr/bin/env ruby

require 'octokit'

class OctokitUtils
  attr_accessor :client


  def initialize(access_token)
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(:access_token => "#{access_token}")
    client.user.login

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
    results ||= client.search_code(query)
    return results

  end

end

