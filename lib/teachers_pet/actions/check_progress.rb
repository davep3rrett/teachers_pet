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

      def get_num_commits(repo)
        begin
          commits = self.client.list_commits(repo.full_name)
        rescue Exception => e
          puts e.message
          return nil
        end
        unless commits.nil?
          return commits.length
        end
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
            csv << [student, user.name, "#{student}-#{@repository}", repo.description, get_num_commits(repo), 'ADDITIONS', 'DELETIONS', get_last_commit_date(repo)]
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
