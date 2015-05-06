class MapsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
 # def setup
 #   sign_in users(:user1)
 # end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:maps)
  end
end