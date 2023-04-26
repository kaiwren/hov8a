# Run this like so:
# First param is the csv file
# Second param is the attendance threshold in minutes
# c:\> ruby processor.rb day_1.csv 120
#
# this will produce the following output:
#
# Attendee Details section found at row 24
# 10003 unique emails found among all rows 11265
# 1549 unique attendee emails found among 2811 attendees
# 2811 rows written to attendees_day_1.csv
# 8454 rows written to non_attendees_day_1.csv
# 1549 rows written to unique_attendees_day_1.csv
# 467 rows written to unique_attendees_above_attendance_threshold_day_1.csv

require 'csv'
require 'date'
require 'pp'

file_1_path = ARGV[0]
attendance_threshold_in_minutes = ARGV[1].to_i

attendees_file_path = "attendees_#{file_1_path}"
non_attendees_file_path = "non_attendees_#{file_1_path}"
unique_attendees_file_path = "unique_attendees_#{file_1_path}"
unique_attendees_above_attendance_threshold_file_path = "unique_attendees_above_attendance_threshold_#{file_1_path}"


file_1_text = File.readlines(file_1_path)

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
    duplicate_attendees.each {|attendee| total_time_in_session += attendee[9].to_i }
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
  attendee[9].to_i > attendance_threshold_in_minutes
end

CSV.open(unique_attendees_above_attendance_threshold_file_path, 'w') do |csv|
  unique_attendees_above_attendance_threshold.each { |row| csv << row }
end

puts "#{unique_attendees_above_attendance_threshold.count} rows written to #{unique_attendees_above_attendance_threshold_file_path}"
