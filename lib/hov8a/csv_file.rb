# frozen_string_literal: true

module Hov8a
  class CsvFile
    include Export
    attr_reader :file_path, :attendance_threshold, :out_dir

    def initialize(file_path, attendance_threshold, out_dir)
      @file_path = file_path
      @attendance_threshold = attendance_threshold
      @out_dir = out_dir
      @marker_indicating_start_of_attendee_section = "Attendee Details,\n"
    end

    def file_contents
      @file_contents ||= File.read(file_path)
    end

    def unique_emails
      @unique_emails ||= rows_of_attendee_data.map { |row| row[4] }.uniq
    end

    def row_number_of_attendee_details
      location = file_contents.index(@marker_indicating_start_of_attendee_section)
      raise 'Attendee Details section badly demarcated' if location.nil?

      location + @marker_indicating_start_of_attendee_section.length
    end

    def file_contents_without_panelists
      @file_contents_without_panelists ||= file_contents[row_number_of_attendee_details..]
    end

    def rows_of_attendee_data
      @rows_of_attendee_data ||= CSV.new(file_contents_without_panelists, headers: true, liberal_parsing: true).read
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

    def non_attendee_emails_non_unique
      non_attendees.map { |non_attendee| non_attendee[4] }
    end

    def unique_attendees_with_time_in_session_summed
      unique_attendee_emails.map do |unique_email|
        duplicate_attendees = attendees.select { |attendee| attendee[4] == unique_email }
        if duplicate_attendees.count > 1
          sum_time_in_session_for_duplicate_attendees(duplicate_attendees)
        else
          duplicate_attendees[0]
        end
      end
    end

    def unique_attendees_above_attendance_threshold
      return @unique_attendees_above_attendance_threshold if @unique_attendees_above_attendance_threshold

      @unique_attendees_above_attendance_threshold,
        @unique_attendees_below_attendance_threshold = split_unique_attendees_into_delinquent_and_non_delinquent
      @unique_attendees_above_attendance_threshold
    end

    def unique_attendees_below_attendance_threshold
      return @unique_attendees_below_attendance_threshold if @unique_attendees_below_attendance_threshold

      @unique_attendees_above_attendance_threshold,
        @unique_attendees_below_attendance_threshold = split_unique_attendees_into_delinquent_and_non_delinquent
      @unique_attendees_below_attendance_threshold
    end

    def process!
      Kernel.puts "Processing #{file_path} with attendance threshold #{attendance_threshold} minutes"

      FileUtils.mkdir_p(out_dir)

      file_name = File.basename(file_path)
      input_text_to_csv_parser = File.join(out_dir, "preprocessed_#{file_name}")
      attendees_file_path = File.join(out_dir, "attendees_#{file_name}")
      non_attendees_file_path = File.join(out_dir, "non_attendees_#{file_name}")
      unique_attendees_file_path = File.join(out_dir, "unique_attendees_#{file_name}")
      unique_attendees_above_attendance_threshold_file_path = File.join(
        out_dir,
        "unique_attendees_above_attendance_threshold_#{file_name}"
      )

      File.write(input_text_to_csv_parser, file_contents_without_panelists)
      Kernel.puts "Input file to CSV parser #{input_text_to_csv_parser}"

      Kernel.puts "Attendee Details section found at position #{row_number_of_attendee_details}"
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
                  "#{unique_attendees_above_attendance_threshold.count} rows written \
to #{unique_attendees_above_attendance_threshold_file_path}")
    end

    private

    def sum_time_in_session_for_duplicate_attendees(duplicate_attendees)
      total_time_in_session = 0
      duplicate_attendees.each { |attendee| total_time_in_session += attendee[9].to_i }
      collated_attendee = duplicate_attendees[0].dup
      collated_attendee[9] = total_time_in_session.to_s
      collated_attendee
    end

    def split_unique_attendees_into_delinquent_and_non_delinquent
      unique_attendees_with_time_in_session_summed.partition do |attendee|
        attendee[9].to_i > attendance_threshold
      end
    end

    def split_attendees_and_non_attendees
      rows_of_attendee_data.partition { |row| row[0] == 'Yes' }
    end
  end
end
