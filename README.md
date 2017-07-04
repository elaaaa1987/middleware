# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version
	ruby 2.4.0p0
	Rails 5.1.2

* System dependencies

* Configuration

* Database creation
	rake db:create RAILS_ENV=production


* Database initialization
	rake db:migrate RAILS_ENV=production

	#Envirnoment varaibles setup
	#Your api domain path
	export API_DOMAIN="https://makoitlab.freshdesk.com/api/v2/"
	#Your api key
	export API_KEY="zic7Prl6hlO18uv7qDgB"
	#Your account id
	export ACCOUNT_ID=30000321354

	rake db:seed RAILS_ENV=production

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
