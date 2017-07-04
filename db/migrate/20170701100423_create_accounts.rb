class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts do |t|
      t.integer :account_id
      t.string :api_domain
      t.string :api_key

      t.timestamps
    end
    change_column :accounts, :account_id, 'bigint'
  end
end
