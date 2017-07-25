class AddDomainNameToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :domain_name, :string
  end
end
