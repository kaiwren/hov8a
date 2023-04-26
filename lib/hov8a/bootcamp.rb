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

    def unique_attendee_emails
      @unique_attendee_emails ||= (
        @day_1_file.unique_attendee_emails +
          @day_2_file.unique_attendee_emails
      ).uniq
    end

    def bootcamp_non_attendees_email_index
      return @bootcamp_non_attendees_email_index if @bootcamp_non_attendees_email_index

      @bootcamp_non_attendees_email_index = {}
      bootcamp_non_attendees = @day_1_file.non_attendees + @day_2_file.non_attendees
      bootcamp_non_attendees.each do |non_attendee|
        @bootcamp_non_attendees_email_index[non_attendee[4]] ||= non_attendee
      end
      @bootcamp_non_attendees_email_index
    end

    def bootcamp_attendees_below_threshold
      @bootcamp_attendees_below_threshold ||= @day_1_file.unique_attendees_below_attendance_threshold +
                                              @day_2_file.unique_attendees_below_attendance_threshold
    end

    def unique_non_attendees
      @unique_non_attendees ||= unique_non_attendee_emails.map do |unique_email|
        bootcamp_non_attendees_email_index[unique_email]
      end
    end

    def unique_attendees_below_threshold
      @unique_attendees_below_threshold ||= unique_attendee_emails.map do |unique_email|
        bootcamp_attendees_below_threshold.find { |attendee| attendee[4] == unique_email }
      end.compact
    end

    def process!
      @day_1_file.process!
      @day_2_file.process!
      unique_non_attendees_path = File.join(@out_dir, 'unique_non_attendees_across_both_days.csv')
      unique_attendees_below_threshold_path = File.join(@out_dir, 'unique_attendees_across_both_days_below_threshold.csv')
      unique_non_attendees_and_unique_attendees_below_threshold_path = File.join(@out_dir, 'unique_non_attendees_and_unique_attendees_below_threshold.csv')

      Kernel.puts('Please wait...')
      export_csv!(unique_non_attendees_path,
                  unique_non_attendees,
                  "#{unique_non_attendees.count} bootcamp-wide unique non attendees exported to #{unique_non_attendees_path}")

      export_csv!(unique_attendees_below_threshold_path,
                  unique_attendees_below_threshold,
                  "#{unique_attendees_below_threshold.count} bootcamp-wide unique attendees below attendance threshold exported to #{unique_attendees_below_threshold_path}")

      export_csv!(unique_non_attendees_and_unique_attendees_below_threshold_path,
                  unique_non_attendees + unique_attendees_below_threshold,
                  "#{unique_non_attendees.count + unique_attendees_below_threshold.count} bootcamp-wide unique non attendees and unique attendees below attendance threshold exported to #{unique_non_attendees_and_unique_attendees_below_threshold_path}")
    end
  end
end
