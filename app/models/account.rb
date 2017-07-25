class Account < ApplicationRecord
	validates :api_domain, presence: true
	validates :api_key, presence: true
end
