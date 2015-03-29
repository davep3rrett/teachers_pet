module TeachersPet
  class Cli
    option :organization, required: true

    students_option
    common_options
    
    desc 'check_progress', "Generate CSV files for each repo belonging to each student in the organization, listing number of commits and other information."
    def  check_progress
      TeachersPet::Actions::CheckProgress.new(options).run
    end
  end
end
