require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_numbers(phonenumber)
  number = phonenumber.gsub(/\D/, "")
  invalid = 'Invalid Number'
  if number.length < 10
    invalid
  elsif number.length == 11 && number[0] == "1"
    number[1..10]
  elsif number.length == 11 && number[0] != "1"
    invalid
  elsif number.length > 11
    invalid
  else
    number
  end
  
end

def get_hour(time)
  DateTime.strptime(time, "%m/%d/%y %H:%M").hour
end

def get_day(time)
  DateTime.strptime(time, "%m/%d/%y %H:%M").strftime("%A")
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def track_info(id, tracking_form)
  Dir.mkdir('tracking') unless Dir.exist?('tracking')

  filename = "tracking/info_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts tracking_form
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

tracking_info = File.read('people_info.erb')
erb_tracking = ERB.new tracking_info

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  registered_time = get_hour(row[:regdate])
  phone_number = clean_numbers(row[:homephone])
  day = get_day(row[:regdate])


  form_letter = erb_template.result(binding)
  tracking_form = erb_tracking.result(binding)

  save_thank_you_letter(id,form_letter)
  track_info(id, tracking_form)

end
