# frozen_string_literal: true

RSpec.describe Hov8a::CsvFile do
  let(:day_1_file) { described_class.new('spec/data/day_1.csv', 120, '/tmp/out') }

  it 'has the expected number of rows of attendee data' do
    expect(day_1_file.rows_of_attendee_data.count).to eq(11_265)
  end

  it 'has the expected number of unique emails' do
    expect(day_1_file.unique_emails.count).to eq(10_003)
  end

  it 'has the expected number of attendees' do
    expect(day_1_file.attendees.count).to eq(2_811)
  end

  it 'has the expected number of non-attendees' do
    expect(day_1_file.non_attendees.count).to eq(8_454)
  end
end
