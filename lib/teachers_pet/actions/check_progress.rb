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

      def get_stats(repo)

        # If the contributors stats for a certain repo have not yet been calculated by GitHub, this API call will fire a
        # background job to calculate them, so there are cases where you will get a "202 Accepted", but then if you try the API call
        # a moment later, you will get the stats you were asking for.

        begin
          stats = self.client.contributors_stats(repo.full_name)
          while client.last_response.headers["status"] == "202 Accepted"
            puts "Got status 202 Accepted for repository #{repo.full_name}."
            puts "Waiting 5 seconds for Github to calculate stats and trying again..."
            sleep(5)
            stats = self.client.contributors_stats(repo.full_name)
          end
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

        # Provide a default filename for the CSV file if the --filename option is not passed
        if @filename.nil?
          @filename = "#{@repository}.csv"
        end

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
