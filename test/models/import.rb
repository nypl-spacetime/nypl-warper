require 'test_helper'
require 'vcr'


VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock 
end

class ImportTest < ActiveSupport::TestCase

  def teardown
    Import.all.each do | import | 
      if File.exist? "log/#{import.logfile}"
        puts "deleting test log #{import.logfile}"
        File.delete "log/#{import.logfile}"
      end
    end
  end


  test "should be invalid with an invalid date" do
    import = Import.new(:import_type=> :latest, :since_date => "abcd-11-11", :until_date => "1020-11-11")
    assert_not import.valid?
    
    import = Import.new(:import_type=> :latest, :since_date => "1011-11-11", :until_date => "1020/11/11")
    assert_not import.valid?
  end
  
  test "should not save import without a param" do
    import = Import.new
    assert_not import.save
  end

  test "should save import with a uuid" do
    import = Import.new(:uuid => "abcd")
    assert import.save
  end

  test "default value" do
    import = Import.new(:uuid => "asca")
    assert_equal :ready, import.status
  end

  test "should not save import with just one since or until" do
    import = Import.new(:since_date => "1020-11-11")
    assert_not import.save

    import = Import.new(:until_date => "1020-11-11")
    assert_not import.save
  end

  test "should save new import with since and until" do
    import = Import.new(:import_type=> :latest, :since_date => "1000-00-00", :until_date=>"2222-22-22")
    assert import.save
  end

  test "should have a log file name" do
    import = Import.new uuid: "absc"
    import.save
  
    assert import.logfile
    assert_match(/.log/, import.logfile)
    assert_match(/import-map/, import.logfile)
  end


  #This calls the NYPL Repo API
  test "should actually import a map and any layer" do

    VCR.use_cassette("get_map") do

      map_count = Map.count
      layer_count = Layer.count
  
      #http://digitalcollections.nypl.org/items/510d47e4-68a5-a3d9-e040-e00a18064a99
      import = Import.new uuid: "510d47e4-68a5-a3d9-e040-e00a18064a99"
      import.save
      import.import!

      assert_equal :finished, import.status
      assert_equal map_count+1, Map.count
      assert layer_count+2, Layer.count

      map = Map.find_by_uuid "510d47e4-68a5-a3d9-e040-e00a18064a99"
      assert_match /The SOUTH-WEST coast of IRELAND from/,  map.title
      layer = map.layers.first
      assert_match /sea-atlas/, layer.name
    end
  end

  test "should import a layer" do

    VCR.use_cassette("get_layer") do
      map_count = Map.count
      layer_count = Layer.count
      #http://digitalcollections.nypl.org/items/61b469d0-c603-012f-c5ab-58d385a7bc34#/?uuid=510d47e4-7369-a3d9-e040-e00a18064a99
      import = Import.new(uuid: "61b469d0-c603-012f-c5ab-58d385a7bc34", import_type: :layer)
      import.save
      import.import!
  
      assert_equal :finished, import.status
      assert_equal map_count+1, Map.count
      assert layer_count+2, Layer.count

      layer = Layer.find_by_uuid  "61b469d0-c603-012f-c5ab-58d385a7bc34"
      assert_match /Iconography of Manhattan Island/,  layer.name
      map =  layer.maps.first
      assert_match /Redraft of the Castello Plan/, map.title

    end

  end

  test "should count latest" do
    VCR.use_cassette("count_latest") do
    
      import = Import.new(import_type: :latest, since_date: "2015-03-27", until_date: "2015-04-01" )
      import.save
      count = import.count_latest
      assert_equal 2, count
    end
  end

  test "should import latest" do
    VCR.use_cassette("import_latest") do
      map_count = Map.count
      layer_count = Layer.count
      #http://api.repo.nypl.org/api/v1/items/search.json?q=%22Map%20Division%22&field=physicalLocation&since=2015-03-27&until=2015-04-01&per_page=500
    
      import = Import.new(import_type: :latest, since_date: "2015-03-27", until_date: "2015-04-01" )
      import.save
      import.import!
  
      assert_equal :finished, import.status
      assert_equal map_count+2, Map.count
      assert_equal layer_count+2, Layer.count

      map = Map.last
      layer = map.layers.first

      assert_match /Province de Chen-si/ , map.title
      assert_match /Atlas générale de la Chine/, layer.name

    end

  end


end
