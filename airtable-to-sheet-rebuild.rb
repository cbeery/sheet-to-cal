#!/usr/bin/env ruby

load 'airtable-to-sheet-shared.rb'
drive_setup

def process_steam_rows(results)
	results['records'].each do |record|
		fields = record['fields']

		unless fields['Date'].nil?
			puts fields['Date']
			sheet_columns = [[fields['Date'], fields['Locale Text'], fields['Shorts-Socks-Shoes'], fields['Activities Text'], fields['Venues Text'], fields['Interactions Text'], fields['Notes Text'], record['id']]]
			value_range = Google::Apis::SheetsV4::ValueRange.new(values: sheet_columns)
			result = @drive.append_spreadsheet_value(STEMS_SHEET_ID, 'SteamToCal', value_range, value_input_option: 'RAW')
			sleep 1
		end

	end
end

# Clear all existing values
result = @drive.clear_values(STEMS_SHEET_ID, 'SteamToCal')
puts "Cleared."

url = 'https://api.airtable.com/v0/appCdpOEVQYmo995T/Outfits'
uri = URI(url)
# params = {view: 'iCal', api_key: AIRTABLE_API_KEY, pageSize: 1}
params = {view: 'iCal', api_key: AIRTABLE_API_KEY, pageSize: 100, 'sort[0][field]' => 'Date', 'sort[0][direction]' => 'asc'}
uri.query = URI.encode_www_form(params)
results = JSON.parse(Net::HTTP.get(uri))

# puts results

process_steam_rows(results)

while results['offset'] do
	params[:offset] = results['offset']

	uri.query = URI.encode_www_form(params)
	results = JSON.parse(Net::HTTP.get(uri))

	process_steam_rows(results)
	
end

