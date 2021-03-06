require 'json'
class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:contacts, :add_account]
  before_action :get_api_creds
  before_action :check_account, :only =>[:add_account]
	#To add or update contact in freshdesk from autopilot webhook callback
	def contacts
	  #begin
	    autopilot_contact = params["contact"]
	    autopilot_event = params["event"]
	    if autopilot_contact.has_key?("Company") && autopilot_contact["Company"] != ""
          company_id = get_freshdesk_company_id(autopilot_contact["Company"])
          #Rails.logger.debug "comp id==>#{company_id}"
          autopilot_contact["Company"] = company_id 
        end
        @freshdesk_data = initialize_freshdesk_data(autopilot_contact,autopilot_contact["event"])
        @freshdesk_data["company_id"] = autopilot_contact["Company"] unless autopilot_contact["Company"] == ""

	    #@freshdesk_data = initialize_freshdesk_data(autopilot_contact,autopilot_contact["event"])
	    get_custom_fields(autopilot_contact)
	    if autopilot_event == "contact_added"
	  	  response = contact_added(@freshdesk_data)
	    elsif autopilot_event == "contact_updated"
		  #Rails.logger.info "Update response from autopilotttttttttttttttttt"
	      response = contact_updated(@freshdesk_data, @freshdesk_contact_id)
		  #Rails.logger.debug "#{response}"		
	    end 
	    response.parsed_response.has_key?("errors") ? failure_response(response) : success_response
	  #rescue Exception => e
	  #	puts e.message
	  #end
	end

	def add_account
		if @account.nil?
			@account = Account.create(set_account_params)
		else
			@account.update_attributes(set_account_params)
		end
		#Rails.logger.debug "#{@account}"
		if @account
			render :json => {"status" => true, "message" => "Success", "body" => @account}
		else
			render :json => {"status" => false, "message" => "Failed"}
		end
	end

	private 

	def get_freshdesk_company_id(comp)
       response = HTTParty.get(
        "#{@api_domain}companies",
        basic_auth: { username: @api_key, password: "password" },
        headers: { 'Content-Type' => 'application/json' }
        )
        
        #Rails.logger.info "company response====="
        #Rails.logger.debug "#{response}"
        company_id = response.collect{|x| p x["id"] if x["name"] == comp}.compact.first
        #Rails.logger.debug "#{response.collect{|x| p x["id"] if x["name"] == comp}.compact}"
        #Rails.logger.debug "#{company_id}"
        if company_id.nil?
            response = HTTParty.post(
                    "#{@api_domain}companies",
                    basic_auth: { username: @api_key, password: "password" },
                    headers: { 'Content-Type' => 'application/json' },
                    body: {'name' => comp}.to_json
            )
            Rails.logger.info "Company Created"
            Rails.logger.debug "#{response}"
	   
            company_id = response["id"] if response
        end
        
       company_id
    end


	#To initialize freshdesk api data
	def initialize_freshdesk_data(autopilot_contact,autopilot_event)
		lastname = autopilot_contact["LastName"].nil? ? "" : autopilot_contact["LastName"]
	  {
	    "name" => autopilot_contact["FirstName"] +" "+lastname,
	  	"email" => autopilot_contact["Email"],
	  	"phone" => autopilot_contact["Phone"].nil? ? "" : autopilot_contact["Phone"].to_s,
		"job_title" => autopilot_contact["Title"],
	  	"mobile" => autopilot_contact["MobilePhone"].nil? ? "" : autopilot_contact["MobilePhone"].to_s,
	  	"twitter_id" => autopilot_contact["Twitter"],
	  	"address" => get_address(autopilot_contact),
	  	"custom_fields" => {}
	  }
	end

	#To get the custom fileds 
	def get_custom_fields(autopilot_contact)
	  if autopilot_contact.has_key?("custom")
  		autopilot_contact["custom"].each do |key,value|
			#if !cf["deleted"]
				#Rails.logger.info "cutom fieldsssssssssssss"
				#Rails.logger.info "#{key}"
				#Rails.logger.debug "#{value}"
				custom_field_value = value
				custom_field_type, custom_field = key.split("--")
				#Rails.logger.debug "custom field-->#{custom_field}-#{custom_field_value}"
				case custom_field
				when "FDADDRESS"
					@freshdesk_data["address"] = custom_field_value
				when "FDACCOUNTID"
					@freshdesk_account_id = custom_field_value
				when "FDCONTACTID"
					@freshdesk_contact_id = custom_field_value
				else
				  #@freshdesk_data["custom_fields"][cf["kind"]] = custom_field_value
				end	
			#end
		end
   	   end
	end

	#To get concatenate address 
	def get_address(autopilot_contact)
		address = []
		address << autopilot_contact["MailingStreet"] unless autopilot_contact["MailingStreet"].nil?
		address << autopilot_contact["MailingCity"] unless autopilot_contact["MailingCity"].nil?
		address << autopilot_contact["MailingCountry"] unless autopilot_contact["MailingCountry"].nil?
		address.join(",")
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
		#Rails.logger.info "Update method id and data"
		#Rails.logger.debug "#{@api_domain}-#{contact_id}-#{@api_key}"
		#Rails.logger.debug "#{freshdesk_data.to_json}"
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
	  		Rails.logger.info "======================="
	  		Rails.logger.debug "#{e['field']}  - #{e['message']}"
	  		Rails.logger.info "=========================="
	  	end
	  	render :json => {"status" => false, "message" =>  response.parsed_response["errors"] }
	end

    #To get api credentianls from account in middleware app
	def get_api_creds
		#account = Account.first
		p 1111111111111
		Rails.logger.info "get api details"
		Rails.logger.debug "#{params}"
		account = Account.find_by(:domain_name => params["domain_name"])
		@api_domain = account.try(:api_domain)
		@api_key = account.try(:api_key)
	end

	def check_account
		@account = Account.find_by(:domain_name => params["account"]["domain_name"])
	end

	def set_account_params
		params.require(:account).permit(:domain_name, :api_domain, :api_key)
	end

end
