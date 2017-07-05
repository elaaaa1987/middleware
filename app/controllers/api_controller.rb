
class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:contacts]
  before_action :get_api_creds
	#To add or update contact in freshdesk from autopilot webhook callback
	def contacts
	  begin
	    autopilot_contact = params["contact"]
	    autopilot_event = params["event"]
	    @freshdesk_data = initialize_freshdesk_data(autopilot_contact,autopilot_contact["event"])
	    get_custom_fields(autopilot_contact)
	    if autopilot_event == "contact_added"
	  	  response = contact_added(@freshdesk_data)
	    elsif autopilot_event == "contact_updated"
	          response = contact_updated(@freshdesk_data, @freshdesk_contact_id)		
	    end 
	    response.parsed_response.has_key?("errors") ? failure_response(response) : success_response
	  rescue Exception => e
	  	puts e.message
	  end
	end

	private 

	#To initialize freshdesk api data
	def initialize_freshdesk_data(autopilot_contact,autopilot_event)
	  {
	    "name" => autopilot_contact["FirstName"] +" "+autopilot_contact["LastName"],
	  	"email" => autopilot_contact["Email"],
	  	"phone" => autopilot_contact["Phone"],
	  	"mobile" => autopilot_contact["MobilePhone"],
	  	"twitter_id" => autopilot_contact["Twitter"],
	  	"address" => get_address(autopilot_contact),
	  	"custom_fields" => {}
	  }
	end

	#To get the custom fileds 
	def get_custom_fields(autopilot_contact)
	  if autopilot_contact.has_key?("custom_fields")
  		autopilot_contact["custom_fields"].each do |cf|
			if !cf["deleted"]
				custom_field_value = cf["value"]
				case cf["kind"]
				when "FDADDRESS"
					@freshdesk_data["address"] = custom_field_value
				when "FDACCOUNTID"
					@freshdesk_account_id = custom_field_value
				when "FDCONTACTID"
					@freshdesk_contact_id = custom_field_value
				else
				  #@freshdesk_data["custom_fields"][cf["kind"]] = custom_field_value
				end	
			end
		end
   	   end
	end

	#To get concatenate address 
	def get_address(autopilot_contact)
		autopilot_contact["MailingStreet"]+","+autopilot_contact["MailingCity"]+","+autopilot_contact["MailingCountry"]+"-"+autopilot_contact["MailingPostalCode"]
	end

	#To add a contact in freshdesk 
	def contact_added(freshdesk_data)
	  response = HTTParty.post(
	   "#{@api_domain}contacts", 
		  basic_auth: { username: @api_key, password: "password" },
		  headers: { 'Content-Type' => 'application/json' },
		  body: freshdesk_data.to_json
	  )
	end

	#To update contacts in freshdesk
	def contact_updated(freshdesk_data,contact_id)
	  response = HTTParty.put(
	   "#{@api_domain}contacts/#{contact_id}", 
		  basic_auth: { username: @api_key, password: "password" },
		  headers: { 'Content-Type' => 'application/json' },
		  body: freshdesk_data.to_json
	  )
	end

	
    #Response for successfull
    def success_response
		render :json => {"status" => true, "message" => "Success"}
	end

    #Response for Failure
    def failure_response(response)
		puts error = response.parsed_response["description"]
	  	response.parsed_response["errors"].each do |e|
	  		puts "======================="
	  		puts e["field"]+ " - "+e["message"]
	  		puts "=========================="
	  	end
	  	render :json => {"status" => false, "message" =>  response.parsed_response["errors"] }
	end

    #To get api credentianls from account in middleware app
	def get_api_creds
		account = Account.first
		@api_domain = account.try(:api_domain)
		@api_key = account.try(:api_key)
	end

end
