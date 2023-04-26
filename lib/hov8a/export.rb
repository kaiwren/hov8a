# frozen_string_literal: true

module Hov8a
  module Export
    def export_csv!(file_path, rows, message)
      CSV.open(file_path, 'w') do |csv|
        rows.each { |row| csv << row }
      end

      Kernel.puts(message)
    end
  end
end
