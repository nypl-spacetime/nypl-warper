class FlagsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :maps, :layers, :roles, :permissions

  test "create new flag" do
    sign_in users(:user1)
    map = maps(:map1)
    post :create, :flag => { :reason => "error"}, :map_id => map
    
    flag = assigns(:flag)
    assert "Map", flag.flaggable_type
    
    assert_response :redirect
    assert_redirected_to map
    assert flash[:notice].include?("saved")
  end
  
  test "index"do
    sign_in users(:user1)
    get :index
    assert_response :redirect
    assert_redirected_to root_path
    assert flash[:error].include?("Sorry you do not have permission")
    sign_out users(:user1)
    
    sign_in users(:adminuser)
    get :index
    assert_response :ok
    
    flags = assigns(:flags)
    assert_not_nil flags
  end
  
  test "admin can close a flag" do
    sign_in users(:adminuser)
    flag = flags(:map1_flag)
    put :close, :id => flag.id
    assert_response :redirect
    assert_redirected_to map
    assert flash[:notice].include?("closed")
  end
end