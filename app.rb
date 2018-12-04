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

STEMS_SHEET_ID = ENV['STEMS_SHEET_ID']
STEMS_RANGE = 'Pockets'			

FLUIDS_SHEET_ID = ENV['FLUIDS_SHEET_ID']
FLUIDS_RANGE = 'Fluids'

# @drive.get_spreadsheet_values(sheet_id, range)

get '/' do
	"What up?"
end

get '/cal/stems' do
	drive_setup
	cal = Icalendar::Calendar.new
	timezone_setup(cal)
	convert_stems_spreadsheet_rows_to_cal(cal)
end

get '/cal/fluids' do
	drive_setup
	cal = Icalendar::Calendar.new
	timezone_setup(cal)
	convert_fluids_spreadsheet_rows_to_cal(cal)
end

private

def convert_stems_spreadsheet_rows_to_cal(cal)
	response = @drive.get_spreadsheet_values(STEMS_SHEET_ID, STEMS_RANGE)
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

def convert_fluids_spreadsheet_rows_to_cal(cal)
	# Column 1 is ISO8601 datetime format (specified in iOS Shortcuts app)
	# DateTime.iso8601
	response = @drive.get_spreadsheet_values(FLUIDS_SHEET_ID, FLUIDS_RANGE)
	@rows = response.values.drop(1).reverse # .drop ignores header row
	@rows.each_with_index do |row, index|
    cal.event do |e|
    	start = DateTime.iso8601(row[0])
      e.dtstart     = Icalendar::Values::DateTime.new(start)
      e.dtend       = Icalendar::Values::DateTime.new(start + 15.minutes)
      e.summary 		= row[2] # What
      e.location		= row[1] # Where
      e.description = row[3] # Notes, if any
      e.uid					= "bev#{index + 1}"
    end # cal.event
	end # @rows.each
	# cal.to_ical.html_safe
	cal.to_ical.to_s
end

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
