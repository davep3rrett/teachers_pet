module TeachersPet
  module Actions
    class CheckProgress < Base

      def read_info
        @organization = self.options[:organization]
      end

      def load_files
        @students = self.read_students_file
      end

      def get_organization_members
        @organization[:rels][:members].get.data
      end

      def get_user(login)
        Octokit.user(login)
      end

      def get_repos(user)
        user.rels[:repos].get.data
      end

      def build_filename(repo)
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

      def get_last_commit_date(repo)
        begin
          commits = Octokit.list_commits(repo.full_name)
          last_commit_date = commits[0].commit.author[:date]
        rescue Exception => e
          puts e.message
          last_commit_date = nil
        end
        last_commit_date
      end

      def generate_csv(repo)
        CSV.open(build_filename(repo), 'wb') do |csv|
          csv << ['username', 'name', 'repository name', 'repository description', 'total commits', 'last commit']
          user = get_user(repo[:owner][:login])
          csv << [repo[:owner][:login], user.name, repo.name, repo.description, get_num_commits(repo), get_last_commit_date(repo)]
        end
      end  

      def run
        self.get_organization_members(@organization).each do |member|
          self.get_repos(member).each do |repo|
            self.generate_csv(repo)
          end
        end
      end
      
    end
  end
end
