#!/usr/bin/env ruby

require 'octokit'
require 'highline/import'
require 'csv'

#------------------function defs-------------------

def get_credentials()
  print 'Enter GitHub username: '
  username = gets.chomp
  password = HighLine.ask("Enter your password:  ") { |q| q.echo = false }
  Hash[:user => username, :pass => password]
end

def authenticate(credentials)
  Octokit.configure do |c|
    c.login = credentials[:user]
    c.password = credentials[:pass]
  end
end

def get_organization()
  print 'Enter name of the organization you want to inspect: '
  Octokit.organization(gets.chomp)
end

def get_organization_members(organization)
  organization[:rels][:members].get.data
end

def get_user(login)
  Octokit.user(login)
end

def get_repos(user)
  user.rels[:repos].get.data
end

def build_filename(repo)
  #look up how to get username from a repo object - repo.owner probably isn't right
  repo[:owner][:login] + '-' + repo.name + '.csv'
end


def get_num_commits(repo)
  total_commits = 0
  begin
    Octokit.list_commits(repo.full_name).each do |commit|
      total_commits += 1
    end
  rescue Exception => e
    puts e.message
    puts "setting number of commits to 0..."
    total_commits = 0
  end  
  total_commits
end

def generate_csv(repo)
  CSV.open(build_filename(repo), 'wb') do |csv|
    csv << ['username', 'name', 'repository name', 'repository description', 'total commits', 'last commit']
    user = get_user(repo[:owner][:login])
    csv << [repo[:owner][:login], user.name, repo.name, repo.description, get_num_commits(repo)]
  end
end  

# ---------------the action--------------------

Octokit.auto_paginate = true #attempt to get all commits instead of just the first page!

puts 'This script is testing the functionality of octokit.rb!'
puts 'In order to access the GitHub API, you\'re going to need some login credentials...'

authenticate(get_credentials)

organization = get_organization

puts 'generating CSV files...'

get_organization_members(organization).each do |member|
  get_repos(member).each do |repo|
    generate_csv(repo)
  end
end

puts 'done!'
