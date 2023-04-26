# frozen_string_literal: true

module Hov8a
  class Bootcamp
    include Export

    def initialize(file_1_path, file_1_attendance_threshold_in_minutes,
                   file_2_path, file_2_attendance_threshold_in_minutes, out_dir)
      @day_1_file = Hov8a::CsvFile.new(file_1_path, file_1_attendance_threshold_in_minutes, out_dir)
      @day_2_file = Hov8a::CsvFile.new(file_2_path, file_2_attendance_threshold_in_minutes, out_dir)
      @out_dir = out_dir
    end

    def unique_non_attendee_emails
      @unique_non_attendee_emails ||= (
        @day_1_file.non_attendee_emails_non_unique +
          @day_2_file.non_attendee_emails_non_unique
      ).uniq
    end

    def bootcamp_non_attendees
      @bootcamp_non_attendees ||= @day_1_file.non_attendees + @day_2_file.non_attendees
    end

    def unique_non_attendees
      unique_non_attendee_emails.map do |unique_email|
        bootcamp_non_attendees.find { |non_attendee| non_attendee[4] == unique_email }
      end
    end

    def process!
      @day_1_file.process!
      @day_2_file.process!
      unique_non_attendees_path = File.join(@out_dir, 'unique_non_attendees.csv')
      export_csv!(unique_non_attendees_path,
                  unique_non_attendees,
                  "#{unique_non_attendees.count} bootcamp-wide unique non attendees exported to #{unique_non_attendees_path}")
    end
  end
end
