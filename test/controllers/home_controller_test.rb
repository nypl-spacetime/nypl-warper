class HomeControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:maps)
  end
end