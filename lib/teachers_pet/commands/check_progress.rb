module TeachersPet
  class Cli
    option :organization, required: true
    students_option
    common_options
    
    desc 'check_progress', "Generate a CSV progress report for each student"
    
    def check_progress
      TeachersPet::Actions::CheckProgress.new(options).run
    end
  end
end
