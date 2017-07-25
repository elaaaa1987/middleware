class DeleteAccountIdFromAccount < ActiveRecord::Migration[5.1]
  def change
  	remove_column :accounts, :account_id
  end
end
