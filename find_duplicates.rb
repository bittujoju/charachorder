# frozen_string_literal: true

require 'csv'

first_column_counts = Hash.new(0)

CSV.foreach('chords.csv') do |row|
  keys = row[0].split(',')
  keys.each { |key| first_column_counts[key] += 1 }
end

puts 'Duplicate chords'
first_column_counts.each do |key, count|
  puts "#{key}: #{count} occurrences" if count > 1
end
