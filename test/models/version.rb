require 'test_helper'

class VersionTest < ActiveSupport::TestCase
  PaperTrail.enabled = true
  PaperTrail.enabled_for_controller = true
 
  
  def setup 
    @map = Map.find(maps(:map1).id)
  end
  
 
  test "changing map title gives new version" do
     
    new_title = "Warped map v2"
    old_title = @map.title
    @map.title =  new_title 
   
    @map.save
    assert_not_empty @map.versions
    assert_not_equal @map.title, old_title
    
    version = @map.versions.first
    assert_equal "update", version.event
    
    reified_map = version.reify
   
    assert_equal reified_map.title, old_title
    
    prev_map = @map.previous_version
    assert_equal prev_map, reified_map
  end
  
 #self.use_transactional_fixtures = false
#  test "adding and then updating a gcp creates a new version" do
#    
#    m = Map.new
#    m.title = "new title"
#    m.save
#
#    gcp = Gcp.new(:x => 123, :y =>234,:lat=>1.1, :lon=>1.2)
#    gcp.map = m
#    gcp.save
#    
#    
#    gcp = Gcp.find(gcp.id)
#    gcp.x = 567
#    gcp.save
#   
#    m = Map.last.reload
#     puts m.versions.last.reify(:has_many => true).gcps.inspect
#    reified_gcp =  m.versions.last.reify(:has_many => true).gcps.first
#    
#    assert_equal 123, reified_gcp.x
#    
#  end
  


  
end