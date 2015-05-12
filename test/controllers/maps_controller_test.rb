class MapsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :maps, :roles, :permissions

  
  test "index all maps" do
    get :index
    assert_response :success
    @maps = assigns(:maps)
   
    assert_not_nil @maps
    assert @maps.size == 1
  end
  
  test "show one map" do
    get :show, :id => maps(:map1).id
    assert_response :success
    @map = assigns(:map)

    assert_not_nil @map
    assert_equal maps(:map1).title, @map.title
  end
  
  test "publish not allowed by admin" do
    sign_in users(:user1)
    get :publish, :to => "publish", :id => maps(:map1).id
    assert_response :redirect
        
    assert_redirected_to root_path
    assert flash[:error].include?("Sorry you do not have permission")
  end
       
 
  test "publish allowed by admin" do
    sign_in users(:adminuser)
   
    get :publish, :to => "publish", :id => maps(:map1).id
    assert_response :redirect
    assert_redirected_to maps(:map1)
    
    @map = assigns(:map)
    assert_equal :published, @map.status
    
    assert_redirected_to maps(:map1)
    assert flash[:notice].include?("Map changed. New Status")
  end
  
       
  test "warp map" do
    skip  "not done yet" 
  end
    
  test "clip map" do
    skip  "not done yet" 
  end
    
  
end