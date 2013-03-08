namespace :map do
    desc "Fetches an image from the NYPL images server."
    task(:fetch => :environment) do
        mapscan = Map.find_by_nypl_digital_id(ENV['id'])
        if mapscan.nil?
            print "Map not found."
            exit
        end
        print "Fetching #{mapscan.title}... "
        if mapscan.fetch_from_image_server(true)
            print "Done.\n"
        else
            print "Failed.\n"
        end
    end
end

namespace :map do
  desc "Warp an image."
  task(:warp => :environment) do
    mapscan = Map.find(ENV['id'])
    if mapscan.nil?
      print "Map not found."
      exit
    end
    print "Masking #{mapscan.title}... "
    print mapscan.mask!
    print "\nWarping #{mapscan.title}... "
    print mapscan.warp! ENV['transform'], ENV['resample']
    print "\n"
  end
end

