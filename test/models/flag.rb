class FlagTest < ActiveSupport::TestCase
  
  def setup
    @flag = Flag.new(:reason => :abuse)
    @flag.flaggable_id  = maps(:map1).id
    @flag.flaggable_type = maps(:map1).class
    @flag.reporter = users(:user1)
  end
  
  test "is valid" do   
    assert @flag.valid?
  end
  
  test "has valid reasons" do
    @flag.reason = "whatever"
    assert !@flag.valid?
    
    @flag.reason = "error"
    assert @flag.valid?
  end
  
  test "can be closed by user" do
    @flag.save
    
    assert @flag.closed_at.nil?
    
    @flag.close(users(:adminuser))
    
    assert_equal @flag.closer_id, users(:adminuser).id
    assert !@flag.closed_at.nil?
  end
  
  test "a map can have many flags" do
    @flag.save
    
    map = maps(:map1)
    map_flag  = map.flags.last
    assert_equal @flag, map_flag
    assert_equal "Map", map_flag.flaggable_type
    assert_equal maps(:map1).id, map_flag.flaggable_id
  end
  
  test "a flag can be saved from a map" do
    map = maps(:map1)
    map.flags.create(:reason => "error")
    map_flag  = map.flags.last
  
    assert_not_nil map_flag
    assert_equal "Map", map_flag.flaggable_type
    assert_equal maps(:map1).id, map_flag.flaggable_id
  end
  
  test "all singing and dancing" do
    @flag.message = "This is a message why"
    assert @flag.valid?
    
    @flag.save
    
    @flag.close(users(:adminuser))
    
    assert_equal users(:user1), @flag.reporter
    assert_equal users(:adminuser), @flag.closer
  end
  
  test "sends an email when first created" do
    
  end
end