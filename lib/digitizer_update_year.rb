require 'rubygems'
require 'active_record'
require 'optparse'

options = {}
optparse = OptionParser.new do | opts |
  opts.banner = "Usage file.rb [options] ids (where ids is a comma separated string of ids)"
  options[:force] = false
  opts.on('-f', '--force', 'force saving the year even if it hasnt changed (not currently working) ') do
    options[:force] = true
  end

  options[:all] = false
  opts.on('-a', '--all', 'do all the layers, ignores whats passed in as ids') do
    options[:all] = true
  end

  opts.on('-h','--help', 'Display this screen') do
    puts opts
    exit
  end
end

optparse.parse!


class PGconn
  def self.quote_ident(name)
          '"' + name + '"'
  end
end

class WarperDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(
    :adapter => "postgresql",
    :database => "nypl"
  )
end
class Layer < WarperDatabase
end

class DigitizerDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(
    :adapter => "postgresql",
    :database => "nypl_digitizer"
  )
end
class Building < DigitizerDatabase
  set_table_name "buildings"
end
class District < DigitizerDatabase
  set_table_name "districts"
end
class Hydrography < DigitizerDatabase
  set_table_name "hydrography"
end
class Poi < DigitizerDatabase
  set_table_name "pois"
end
class Transport < DigitizerDatabase
  set_table_name "transport"
end


def save_layer_year(ids, do_all, force)
  if !ids.blank? && !do_all #if theres some ids and if do_all is false
    layers = Layer.find(ids) #find the layers that match the ids
  elsif do_all  
    layers = Layer.find(:all)  #find all of them
  else
    puts "try -h or --help for help"
    exit
  end
  layers.each do |layer|
    unless layer.depicts_year.blank?  #we dont update a feature if it's year hasnt been set
      puts "For layer " + layer.id.to_s
      [Building, District, Hydrography, Poi, Transport].each do | digitizer_table |
        #we skip saving them if it can find a record with the currect date, and if the force option is set to 'false'
        #thus, it will update records if it cannot find any records with the correct date or if force is set to 'true'
        unless digitizer_table.exists?({:layer_year => layer.depicts_year, :layer_id => layer.id}) && !force 
          puts "updating the features in table "+ digitizer_table.name + " with year "+layer.depicts_year
          digitizer_table.update_all({:layer_year => layer.depicts_year}, {:layer_id => layer.id} )
        end #only skip if its the same and force is false
      end
    end #unless depictsyear is empty

  end #each layer

end

#
# START 
#
ids = []
idsarg = ARGV[0] 
if idsarg
  ids = idsarg.split(",").collect{ |s| s.to_i}
end
save_layer_year(ids, options[:all], options[:force])  


