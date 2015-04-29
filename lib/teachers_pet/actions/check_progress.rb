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

        file_name = "#{@organization}.csv"
        repo = self.client.repository(@repository)

        puts "Creating #{file_name}..."

        # Open and write CSV file
        CSV.open(file_name, 'wb') do |csv|
          csv << ['username', 'name', 'repository name', 'repository description', 'total commits', 'last commit']

          @students.keys.each do |student|

            user = get_user(student)
            repos = get_repos(user)

            repos.each do |repo|
              if repo.nil?
                csv << [student, user.name, '', '', '', '']
              else
                csv << [student, user.name, repo.name, repo.description, get_num_commits(repo), get_last_commit_date(repo)]
              end
            end
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
