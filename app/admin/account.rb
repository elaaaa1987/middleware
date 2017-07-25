ActiveAdmin.register Account do
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
permit_params :account_id, :api_domain, :api_key

controller do
    actions :all, :except => [:edit,:show]
end
config.batch_actions = true

index do
  selectable_column
  id_column
  column :api_domain
  column :api_key
  column :created_at
  actions
end

form title: 'New Account' do |f|
    inputs 'Details' do
      input :api_domain
      input :api_key
    end
    actions
end

end
