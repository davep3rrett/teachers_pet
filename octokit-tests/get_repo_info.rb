#!/usr/bin/env ruby

# found this stack overflow question immensely useful:
# http://stackoverflow.com/questions/25570125/get-contents-of-a-file-from-users-public-github-repos-in-ruby

require 'octokit'
require 'highline/import'
require 'csv'

# say hi
puts 'This script is testing the functionality of octokit.rb!'
puts 'In order to access the GitHub API, you\'re going to need some login credentials...'

# get GitHub login credentials
print 'Enter GitHub username: '
username = gets.chomp
password = HighLine.ask("Enter your password:  ") { |q| q.echo = false }

# Provide authentication credentials to GitHub API
Octokit.configure do |c|
  c.login = username
  c.password = password
end

print 'Retrieve public repos for GitHub user: '
current_user = gets.chomp
user = Octokit.user(current_user)



=begin
# retrieve info for all public repos for specified user
repos = user.rels[:repos].get.data

repos.each do |repo|
  total_commits = 0
  puts repo.name
  puts repo.description

  Octokit.list_commits(repo.full_name).each do |commit|
    # there's gotta be a less hacky way to count the number of times this block iterates...
    total_commits += 1
  end

  print 'total commits: '
  puts total_commits
end
=end



puts 'generating CSV file...'

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

puts 'done!'
