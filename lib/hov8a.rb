# frozen_string_literal: true

require 'csv'
require 'date'
require 'fileutils'

require_relative 'hov8a/version'
require_relative 'hov8a/csv_file'

module Hov8a
  class Error < StandardError; end
end
