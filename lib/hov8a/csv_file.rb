# frozen_string_literal: true

module Hov8a
  class CsvFile
    attr_reader :file_path, :attendance_threshold, :out_dir

    def initialize(file_path, attendance_threshold, out_dir)
      @file_path = file_path
      @attendance_threshold = attendance_threshold
      @out_dir = out_dir
      @marker_indicating_start_of_attendee_section = "Attendee Details,\n"
    end

    def file_contents
      @file_contents ||= File.readlines(file_path)
    end

    def unique_emails
      @unique_emails ||= rows_of_attendee_data.map { |row| row[4] }.uniq
    end

    def row_number_of_attendee_details
      file_contents.index(@marker_indicating_start_of_attendee_section) + 1
    end

    def file_contents_without_panelists
      file_contents[row_number_of_attendee_details..-1]
    end

    def rows_of_attendee_data
      CSV.new(file_contents_without_panelists.join, headers: true).read
    end

    def attendees
      return @attendees if @attendees
      @attendees, @non_attendees = split_attendees_and_non_attendees
      @attendees
    end

    def non_attendees
      return @non_attendees if @non_attendees
      @attendees, @non_attendees = split_attendees_and_non_attendees
      @non_attendees
    end

    def unique_attendee_emails
      @unique_attendee_emails ||= attendees.map { |attendee| attendee[4] }.uniq
    end

    def unique_attendees_with_time_in_session_summed
      unique_attendee_emails.map do |unique_email|
        duplicate_attendees = attendees.select { |attendee| attendee[4] == unique_email }
        if duplicate_attendees.count > 1
          total_time_in_session = 0
          duplicate_attendees.each { |attendee| total_time_in_session += attendee[9].to_i }
          collated_attendee = duplicate_attendees[0].dup
          collated_attendee[9] = total_time_in_session.to_s
          collated_attendee
        else
          duplicate_attendees[0]
        end
      end
    end

    def unique_attendees_above_attendance_threshold
      @unique_attendees_above_attendance_threshold ||= unique_attendees_with_time_in_session_summed.select do |attendee|
        attendee[9].to_i > attendance_threshold
      end
    end

    def export_csv!(file_path, rows, message)
      CSV.open(file_path, 'w') do |csv|
        rows.each { |row| csv << row }
      end

      Kernel.puts(message)
    end

    def process!
      Kernel.puts "Processing #{file_path} with attendance threshold #{attendance_threshold} minutes"

      FileUtils.mkdir_p(out_dir)

      file_name = File.basename(file_path)
      attendees_file_path = File.join(out_dir, "attendees_#{file_name}")
      non_attendees_file_path = File.join(out_dir, "non_attendees_#{file_name}")
      unique_attendees_file_path = File.join(out_dir, "unique_attendees_#{file_name}")
      unique_attendees_above_attendance_threshold_file_path = File.join(
        out_dir,
        "unique_attendees_above_attendance_threshold_#{file_name}"
      )

      raise 'Attendee Details section badly demarcated' if row_number_of_attendee_details.nil?

      Kernel.puts "Attendee Details section found at row #{row_number_of_attendee_details}"
      Kernel.puts "#{unique_emails.count} unique emails found among all rows #{rows_of_attendee_data.count}"
      Kernel.puts "#{unique_attendee_emails.count} unique attendee emails found among #{attendees.count} attendees"

      export_csv!(attendees_file_path, attendees, "#{attendees.count} rows written to #{attendees_file_path}")
      export_csv!(non_attendees_file_path,
                  non_attendees, "#{non_attendees.count} rows written to #{non_attendees_file_path}")
      export_csv!(unique_attendees_file_path,
                  unique_attendees_with_time_in_session_summed,
                  "#{unique_attendees_with_time_in_session_summed.count} rows written to #{unique_attendees_file_path}")
      export_csv!(unique_attendees_above_attendance_threshold_file_path,
                  unique_attendees_above_attendance_threshold,
                  "#{unique_attendees_above_attendance_threshold.count} rows written to #{unique_attendees_above_attendance_threshold_file_path}")
    end

    private

    def split_attendees_and_non_attendees
      rows_of_attendee_data.partition { |row| row[0] == 'Yes' }
    end
  end
end
