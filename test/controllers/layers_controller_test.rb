class LayersControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :layers, :roles, :permissions


  test "index all layers" do
    get :index
    assert_response :success
    @layers = assigns(:layers)
   
    assert_not_nil @layers
    assert @layers.length == 2
  end

  
  test "search for map via text" do
    get :index, :field => "text", :query => "second"
    index_layers = assigns(:layers)
    assert index_layers.include? layers(:layer2)
    
    get :index, :field => "text", :query => "layer"
    index_layers = assigns(:layers)
    assert index_layers.include? layers(:layer2)
  end
  
  test "search/index layers for year" do
    get :index, :from => 1800, :to => 2000
    index_layers = assigns(:layers)
    
    assert  index_layers.length == 2
    
    assert index_layers.include? layers(:layer1)
    assert index_layers.include? layers(:layer2)
    
    get :index, :from => 1800, :to => 1900
    index_layers = assigns(:layers)
    
    assert  index_layers.length == 1
    assert_equal false, index_layers.include?(layers(:layer2))
    assert index_layers.include? layers(:layer1)
  end


end
