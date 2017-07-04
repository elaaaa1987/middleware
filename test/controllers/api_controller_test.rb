require 'test_helper'

class ApiControllerTest < ActionDispatch::IntegrationTest
  test "should get contacts" do
    get api_contacts_url
    assert_response :success
  end

end
