module TeachersPet
  module Actions
    class CheckProgress < Base

      require 'csv'
      
      def read_info
        @repository = self.options[:repository]
        @organization = self.options[:organization]
      end

      def load_files
        @students = self.read_students_file
      end

      def get_num_commits(repo)
        total_commits = 0
        begin
          self.client.list_commits(repo.full_name).each do |commit|
            total_commits += 1
          end
        rescue Exception => e
          puts e.message
          puts "setting number of commits to 0..."
          total_commits = 0
        end  
        total_commits
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
        self.client.user(student)
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

        # Generate CSV progress report for each student
        puts "\n Generating CSV progress reports..."
        @students.keys.each do |student|
          unless org_teams.key?(student)
            puts(" ** ERROR ** - no team for #{student}")
            next
          end

          file_name = "#{student}-#{@repository}.csv"
          repo = self.client.repository(@repository)
          user = get_user(student)
          
          CSV.open(file_name, "wb") do |csv|
            csv << ['username', 'name', 'repository name', 'repository description', 'total commits', 'last commit']
  
            csv << [repo[:owner][:login], user.name, repo.name, repo.description, get_num_commits(repo), get_last_commit_date(repo)]
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
