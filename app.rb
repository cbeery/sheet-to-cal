require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/partial'
require 'google/apis/sheets_v4'
require 'signet/oauth_2/client'
require 'dotenv/load'
require 'icalendar'

GOOGLE_CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
GOOGLE_CLIENT_SECRET = ENV['GOOGLE_CLIENT_SECRET']
REFRESH_TOKEN = ENV['REFRESH_TOKEN']

SPREADSHEET_ID = ENV['SPREADSHEET_ID']
RANGE = 'Pockets'

get '/cal' do
	drive_setup
	cal = Icalendar::Calendar.new
	timezone_setup(cal)
	convert_spreadsheet_rows_to_cal(cal)
end

private

def drive_setup
	auth = Signet::OAuth2::Client.new(
	  token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
	  client_id: 						GOOGLE_CLIENT_ID,
	  client_secret: 				GOOGLE_CLIENT_SECRET,
	  refresh_token: 				REFRESH_TOKEN
	)
	auth.fetch_access_token!
	@drive = Google::Apis::SheetsV4::SheetsService.new
	@drive.authorization = auth
end

def timezone_setup(cal)
	# TimeZone
	cal.timezone do |t|
		t.tzid = "America/Denver"

		t.daylight do |d|
			d.tzoffsetfrom = "-0700"
			d.tzoffsetto   = "-0600"
			d.tzname       = "MDT"
			d.dtstart      = "19700308T020000"
			d.rrule        = "FREQ=YEARLY;BYMONTH=3;BYDAY=2SU"
		end # daylight

		t.standard do |s|
			s.tzoffsetfrom = "-0600"
			s.tzoffsetto   = "-0700"
			s.tzname       = "MST"
			s.dtstart      = "19701101T020000"
			s.rrule        = "FREQ=YEARLY;BYMONTH=11;BYDAY=1SU"
		end # standard
	end # timezone
end

def convert_spreadsheet_rows_to_cal(cal)
	response = @drive.get_spreadsheet_values(SPREADSHEET_ID, RANGE)
	@rows = response.values.drop(1).reverse # .drop ignores header row
	@rows.each_with_index do |row, index|
    cal.event do |e|
    	date = Date.parse(row[0]) # Column A = date
      e.dtstart     = Icalendar::Values::Date.new(date)
      e.dtend       = Icalendar::Values::Date.new(date)
      e.summary 		= "#{row[2]} / #{row[3]}"
      e.location		= row[1] # Place
      e.description = "#{row[5]} (#{row[4]})" # Notes (Activity)
      e.uid					= "ks#{index + 1}"
    end # cal.event
	end # @rows.each
	# cal.to_ical.html_safe
	cal.to_ical.to_s
end