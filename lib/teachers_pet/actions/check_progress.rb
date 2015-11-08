module TeachersPet
  module Actions
    class CheckProgress < Base

      require 'csv'
      
      def read_info
        @repository = self.options[:repository]
        @organization = self.options[:organization]
        @filename = self.options[:filename]
      end

      def load_files
        @students = self.read_students_file
      end
      
      def get_all_repos(students)
        # return an array of all the repositories we're going to be dealing with.
        
        repos = Array.new

        students.keys.each do |student|
          repository_name = "#{@organization}/#{student}-#{@repository}"
          user = get_user(student)
          repo = self.client.repository(repository_name)
          repos.push(repo)
        end

        return repos
      end

      def ping_all_repos(repos)
        # fire background jobs to calculate stats for all repos at once, so we can
        # loop through all of them at once five seconds later when the stats are ready.
        # return a hash of the HTTP status codes we get back in case we want to check them.
        
        status_codes = {} # hash to store HTTP response codes per request
        
        repos.each do |repo|
          self.client.contributors_stats(repo.full_name)
          status_codes[repo.full_name] = self.client.last_response.headers["status"]
        end

        return status_codes
      end

      def status_codes_ok?(status_codes)
        # check to see if the background jobs to calculate stats have completed.
        
        status_codes.each do |key, value|
          if value != "200 OK"
            return false
          end
        end

        return true
      end
      
      def get_stats(repo)
        # If the contributors stats for a certain repo have not yet been calculated by GitHub, this API call will fire a
        # background job to calculate them, so there are cases where you will get a "202 Accepted", but then if you try the API call
        # a moment later, you will get the stats you were asking for.
        
        begin
          stats = self.client.contributors_stats(repo.full_name)
          #while self.client.last_response.headers["status"] == "202 Accepted"
          #  puts "Got status 202 Accepted for repository #{repo.full_name}."
          #  puts "Waiting 5 seconds for Github to calculate stats and trying again..."
          #  sleep(5)
          #  stats = self.client.contributors_stats(repo.full_name)
          #end
          rescue Octokit::NotFound => e # don't crash if we get a 404 for some reason
          puts e.message
        end

        commits = 0
        additions = 0
        deletions = 0
        stats.each do |contributor|
          contributor[:weeks].each do |week|
            commits += week[:c]
            additions += week[:a]
            deletions += week[:d]
          end
        end
        return {:commits => commits, :additions => additions, :deletions => deletions}
      end
      
      def get_last_commit_date(repo)
        begin
          commits = self.client.list_commits(repo.full_name)
          last_commit_date = commits[0].commit.author[:date]
        rescue Exception => e
          puts e.message
          last_commit_date = nil
        end
        last_commit_date
      end

      def get_user(student)
        begin
          self.client.user(student)
        rescue
          return nil
        end
      end

      def get_repos(user)
        user.rels[:repos].get.data
      end
      
      def create
        # Authenticate to GitHub
        self.init_client

        # Get hash of organization info
        org_hash = self.client.organization(@organization)
        abort('Organization could not be found') if org_hash.nil?
        puts "Found organization at: #{org_hash[:url]}"
        
        # Load the teams
        org_teams = self.client.get_teams_by_name(@organization)


        # Fire background jobs to calculate contributors stats, and wait until we
        # recieve "200 OK" for all repositories we are looking at.

        @all_repos = get_all_repos(@students)
        
        puts "Asking Github to calculate statistics for all repositories..."

        ping_all_repos(@all_repos)
        sleep(5)

        status_codes = ping_all_repos(@all_repos)

        until status_codes_ok?(status_codes)
          puts "Still waiting for stats..."
          sleep(5)
          status_codes = ping_all_repos(@all_repos)
        end

        # Provide a default filename for the CSV file if the --filename option is not passed
        if @filename.nil?
          @filename = "#{@repository}.csv"
        end
        
        # Write our progress reporting information to a new CSV file.

        puts "Creating #{@filename}..."
        
        CSV.open(@filename, 'wb') do |csv|
          csv << ['username', 'name', 'repository name', 'repository description', 'total commits', 'total additions', 'total deletions', 'last commit']
          
          @students.keys.each do |student|
            repository_name = "#{@organization}/#{student}-#{@repository}"
            user = get_user(student)
            repo = self.client.repository(repository_name)
            stats = get_stats(repo)
            csv << [student, user.name, "#{student}-#{@repository}", repo.description, stats[:commits], stats[:additions], stats[:deletions], get_last_commit_date(repo)]
          end
          
        end
      end
      
      def run
        self.read_info
        self.load_files
        self.create  
      end

    end
  end
end
