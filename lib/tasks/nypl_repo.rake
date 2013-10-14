namespace :map do

  desc "Updates the bibliographic item uuid from the nypl_digital_id using the NYPL Repo API"
  task(:update_bibl_uuid => :environment) do
    desc "updates biblio_uuid for maps"
    puts "This will update the maps uuid based on the nypl_digital_id. This cannot be undone"
    puts "Are you sure you want to continue? [y/N]"
    break unless STDIN.gets.match(/^y$/i)
    count = 0
    unsuccessful = []
    Map.find(:all).each do |map|
      bibl_uuid = NyplRepo.get_bibl_uuid(map.nypl_digital_id.upcase)
      map.bibl_uuid = bibl_uuid
      map.save
      if count % 10 == 0
        STDOUT.print "\r" 
        STDOUT.print count 
        STDOUT.flush
      end
      unsuccessful << map.id if bibl_uuid.nil?
      count = count + 1
      sleep(3) if count % 1000 == 0
    end
    puts "Done " + count.to_s + " maps."
    puts "unsuccessful maps ("+unsuccessful.size.to_s+"):"
    puts unsuccessful.inspect
  end
end

namespace :map do
 desc "Updates the mods_uuid of a map based on the bibliographic uuid and the image id."
 task(:update_mods_uuid => :environment) do
   puts "This will update the mods_uuid of a map. This cannot be undone"
   puts "Are you sure you want to continue? [y/N]"
   break unless STDIN.gets.match(/^y$/i)
   count = 0
   broken = []
   Map.find(:all).each do |map|
     if map.bibl_uuid
       mods_uuid = NyplRepo.get_mods_uuid(map.bibl_uuid, map.nypl_digital_id.upcase)
       if mods_uuid
        map.mods_uuid = mods_uuid
        map.save
       else
         broken << map.id
       end
     end
     
     sleep(10) if count % 100 == 0

     if count % 10 == 0
       STDOUT.print "\r"
       STDOUT.print count.to_s + " " 
       STDOUT.flush
     end

     count = count+ 1
   end
   puts "Done " + count.to_s + " maps."
   puts "unsuccessful maps ("+broken.size.to_s+"):"
   puts broken.inspect

 end

end
    
