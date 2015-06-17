class MapsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :maps, :roles, :permissions

  def teardown 
    # File.Utils rm @inset_map.filename
    FileUtils.rm Dir.glob('test/data/inset*.tif')
  end

  test "index all maps" do
    get :index
    assert_response :success
    @maps = assigns(:maps)
   
    assert_not_nil @maps
    assert @maps.length == 2
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
  
    
  test "create inset not allowed by normal user" do
    sign_in users(:user1)
    post :create_inset, :id => maps(:map1).id
    assert_response :redirect
    assert_redirected_to root_path
    assert flash[:error].include?("Sorry you do not have permission")
  end

  test "create inset not allowed for non ready map" do
    sign_in users(:adminuser)
    post :create_inset, :id => maps(:unloaded)
    assert_response :redirect
    assert_redirected_to maps(:unloaded)
    assert flash[:error].include? ("not ready")
  end



  test "succesfully create inset by admin" do
    sign_in users(:adminuser)
    post :create_inset, :id => maps(:map1)
    inset_map = assigns(:inset_map)
    assert_not_nil inset_map

    assert_response :redirect
    assert_redirected_to inset_map
    assert flash[:notice].include? ("created")
  end
    
  test "get inset maps for a map" do
    get "inset_maps", :id => maps(:map1)
    assert_redirected_to maps(:map1)
    assert flash[:notice].include? "No inset maps"
    assert_empty assigns(:inset_maps)

    map = Map.find(maps(:map1).id)
    inset = map.create_inset
    inset.save
  
    get "inset_maps", :id => maps(:map1)
    
    assert_not_nil assigns(:inset_maps)
    inset_maps = assigns(:inset_maps)
    assert_equal 1, inset_maps.size
 
    assert_response :ok
    assert_template :inset_maps
  end

  
  test "search for map via title" do
    get :index, :field => "title", :query => "unwarped"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
  end
  
  test "search for map via description" do
    get :index, :field => "description", :query => "second"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
    
    get :index, :field => "description", :query => "unwarped"
    index_maps = assigns(:maps)
    assert_equal false, index_maps.include?(maps(:unloaded))
    
  end
  
  test "search for map via text" do
    get :index, :field => "text", :query => "second"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
    
    get :index, :field => "text", :query => "unwarped"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
  end


end
