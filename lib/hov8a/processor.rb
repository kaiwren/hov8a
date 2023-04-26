# frozen_string_literal: true

module Hov8a
  class Processor
    attr_reader :file_path, :attendance_threshold, :out_dir
    def initialize(file_path, attendance_threshold, out_dir)
      @file_path = file_path
      @attendance_threshold = attendance_threshold
      @out_dir = out_dir
    end

    def process!
      puts "Processing #{file_path} with attendance threshold #{attendance_threshold} minutes"

      attendees_file_path = File.join(out_dir, "attendees_#{file_path}")
      non_attendees_file_path = File.join(out_dir, "non_attendees_#{file_path}")
      unique_attendees_file_path = File.join(out_dir, "unique_attendees_#{file_path}")
      unique_attendees_above_attendance_threshold_file_path = File.join(out_dir, "unique_attendees_above_attendance_threshold_#{file_path}")

      file_1_text = File.readlines(file_path)

      row_number_of_attendee_details = file_1_text.index("Attendee Details,\n") + 1

      raise 'Attendee Details section badly demarcated' if row_number_of_attendee_details.nil?

      puts "Attendee Details section found at row #{row_number_of_attendee_details}"

      file_1_text_without_panelists = file_1_text[row_number_of_attendee_details..-1]

      rows = CSV.new(file_1_text_without_panelists.join, headers: true).read

      unique_emails = rows.map { |row| row[4] }.uniq

      puts "#{unique_emails.count} unique emails found among all rows #{rows.count}"

      attendees, non_attendees = rows.partition do |row|
        row[0] == 'Yes'
      end

      unique_attendee_emails = attendees.map { |attendee| attendee[4] }.uniq

      puts "#{unique_attendee_emails.count} unique attendee emails found among #{attendees.count} attendees"

      CSV.open(attendees_file_path, 'w') do |csv|
        attendees.each { |row| csv << row }
      end

      puts "#{attendees.count} rows written to #{attendees_file_path}"

      CSV.open(non_attendees_file_path, 'w') do |csv|
        non_attendees.each { |row| csv << row }
      end

      puts "#{non_attendees.count} rows written to #{non_attendees_file_path}"

      collated_unique_attendees = unique_attendee_emails.map do |unique_email|
        duplicate_attendees = attendees.select { |attendee| attendee[4] == unique_email }
        collated_unique_attendee = if duplicate_attendees.count > 1
                                     total_time_in_session = 0
                                     duplicate_attendees.each { |attendee| total_time_in_session += attendee[9].to_i }
                                     collated_attendee = duplicate_attendees[0].dup
                                     collated_attendee[9] = total_time_in_session.to_s
                                     collated_attendee
                                   else
                                     duplicate_attendees[0]
                                   end
      end

      CSV.open(unique_attendees_file_path, 'w') do |csv|
        collated_unique_attendees.each { |row| csv << row }
      end

      puts "#{collated_unique_attendees.count} rows written to #{unique_attendees_file_path}"

      unique_attendees_above_attendance_threshold = collated_unique_attendees.select do |attendee|
        attendee[9].to_i > attendance_threshold
      end

      CSV.open(unique_attendees_above_attendance_threshold_file_path, 'w') do |csv|
        unique_attendees_above_attendance_threshold.each { |row| csv << row }
      end

      puts "#{unique_attendees_above_attendance_threshold.count} rows written to #{unique_attendees_above_attendance_threshold_file_path}"
    end
  end
end
