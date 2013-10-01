namespace :map do
  desc "Updates the uuid from the nypl_digital_id using the NYPL Repo API"
  task(:updateuuid => :environment) do
    desc "updates uuid for maps"
    puts "This will update the maps uuid based on the nypl_digital_id. This cannot be undone"
    puts "Are you sure you want to continue? [y/N]"
    break unless STDIN.gets.match(/^y$/i)
    count = 0
    unsuccessful = []
    Map.find(:all).each do |map|
      uuid = NyplRepo.get_uuid(map.nypl_digital_id)
      map.uuid = uuid
      map.save
      if count % 10 == 0
        STDOUT.print "\r" 
        STDOUT.print count 
        STDOUT.flush
      end
      unsuccessful << map.id if uuid.nil?
      count = count + 1

      sleep(3) if count % 1000 == 0
    end
    puts "Done " + count.to_s + " maps."
    puts "unsuccessful maps ("+unsuccessful.size.to_s+"):"
    puts unsuccessful.inspect
  end
end
