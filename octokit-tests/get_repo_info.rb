#!/usr/bin/env ruby

# found this stack overflow question immensely useful:
# http://stackoverflow.com/questions/25570125/get-contents-of-a-file-from-users-public-github-repos-in-ruby

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

def get_user()
  print 'Retrieve public repos for GitHub user: '
  github_username = gets.chomp
  Octokit.user(github_username)
end

def generate_csv(user)
  CSV.open('user_info.csv', 'wb') do |csv|
    csv << ['username', 'name', 'repository name', 'repository description', 'total commits']
    repos = user.rels[:repos].get.data
    repos.each do |repo|
      total_commits = 0
      Octokit.list_commits(repo.full_name).each do |commit|
        # there's gotta be a less hacky way to count the number of times this block iterates...
        total_commits += 1
      end
      csv << [user.login, user.name, repo.name, repo.description, total_commits]
    end
  end
end  

# ---------------the action--------------------

puts 'This script is testing the functionality of octokit.rb!'
puts 'In order to access the GitHub API, you\'re going to need some login credentials...'

authenticate(get_credentials)
generate_csv(get_user)

puts 'done!'
