require 'test_helper'

class MapTest < ActiveSupport::TestCase
  
  def setup
    @map = Map.find(maps(:map1).id)
    @inset_map = @map.create_inset
  end
  
  def teardown 
    # File.Utils rm @inset_map.filename
    FileUtils.rm Dir.glob('test/data/inset*.tif')
  end

  test "can create inset maps" do
    map = Map.find(maps(:map1).id)
    inset_map = map.create_inset
    assert inset_map
  end

  test "cannot create inset maps if the file is not there" do
    map = Map.find(maps(:unloaded).id)
    inset_map = map.create_inset
    assert_nil inset_map
  end
  
  test "inset maps get new filename" do
    assert File.exist?(Rails.root.join('test')+@map.filename)
    
    assert_not_equal @map.filename, @inset_map.filename
    assert File.exist?(@inset_map.filename)
  end
  
  test "inset maps get same layers" do
    assert_equal @map.layers, @inset_map.layers    
  end
  
  test "inset maps get unique uuid" do
    assert_not_equal @map.uuid, @inset_map.uuid
  end
  
  test "inset maps get reference to original map" do
    assert_equal @map.id, @inset_map.parent_id
    assert_equal @map, @inset_map.parent
  end
  
  test "parent maps get reference to inset maps" do
    @inset_map.save
    
    assert @map.inset_maps.length == 1
    assert_equal @inset_map, @map.inset_maps[0]
  end
  
  test "cannot create inset map of an inset map" do
    assert_nil @inset_map.create_inset
  end
  
end