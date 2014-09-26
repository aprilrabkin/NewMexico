require 'mechanize'
require "rest_client"
require 'pry-nav'
require 'nokogiri'
require 'csv'

class Scraper 
	attr_reader :rows, :ids, :noko
	def initialize
		@rows = []
	end

	def get_ocd_ids
		page = RestClient.get("https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-us/census_autogenerated/us_census_places.csv")
		noko = Nokogiri::HTML(page)
		@ids = noko.text.lines.select do |line|
			line =~ /state:nm/
		end.reject do |line|
			line =~ /place:/
		end.map do |line|
			line.gsub(/,.+/, '').gsub(/\n/, '')
		end 
	end 

	def fetch_page
		page = RestClient.get("http://www.sos.state.nm.us/Voter_Information/County_Clerk_Information.aspx")
		@noko = Nokogiri::HTML(page).css('#_75bc6d54fa0e4e6088345e3238673465_pnl5c28374aa72044379927f0185b095e61Content') 
	end

	def iterate_through_page
		i = 0
		while i < 33 do #from Bernallilo to Valencia
			county_name = noko.css('h2')[i].text
			office = county_name + " County Clerk"
			phone = noko.css('h2')[i].next_element.text.scan(/\(\d{3}\)\s\d{3}-\d{4}/).first


			link = noko.css('h2')[i].next_element.css('a')
		#	binding.pry
		
			if link.first
				if link.first.attributes['href'] 
					unless link.first.attributes['href'].value.include?("@")
						website = link.first.attributes['href'].value
					end
				end
			else
				website = ""
			end

			id = @ids.find do |i| 
				name = county_name.rstrip.gsub(" County", "").gsub(" ", "_")
				i =~ /county:#{name}/i
			end || ""
			i += 1
			@rows << [county_name + " County", "NM", office, phone, website, id]	
		end


	end			

	def write_into_CSV_file
		CSV.open("spreadsheet.csv", "wb") do |csv|
			@rows.map do |line|
				csv << line
			end
		end
	end

end

a = Scraper.new
a.get_ocd_ids
a.fetch_page
a.iterate_through_page
a.write_into_CSV_file
