#!/usr/bin/env ruby

require 'google/apis/sheets_v4'
require 'signet/oauth_2/client'
require 'dotenv/load'
require 'net/http'

GOOGLE_CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
GOOGLE_CLIENT_SECRET = ENV['GOOGLE_CLIENT_SECRET']
REFRESH_TOKEN = ENV['REFRESH_TOKEN']

AIRTABLE_API_KEY = ENV['AIRTABLE_API_KEY']

STEMS_SHEET_ID = ENV['STEMS_SHEET_ID']

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
