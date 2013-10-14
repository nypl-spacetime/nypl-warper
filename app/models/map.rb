require "open3"
require "ftools"
require "matrix"
require 'nokogiri'
require 'RMagick'


class Map < ActiveRecord::Base
  def self.table_name()
    "mapscans"
  end
   alias_attribute :bibl_uuid, :parent_uuid
   alias_attribute :mods_uuid, :uuid

   has_many :map_layers, :foreign_key => "mapscan_id"
   has_many :layers, :through => :map_layers
   has_many :my_maps, :dependent => :destroy
   has_many :users, :through => :my_maps
      
   has_many :gcps, :foreign_key => "mapscan_id",  :dependent => :destroy  #gcps also destroyed if mapscan is

   acts_as_audited :except => [:filename]

   acts_as_commentable  
   acts_as_enum :status, [:unloaded, :loading, :available, :warping, :warped, :published]
   acts_as_enum :mask_status, [:unmasked, :masking, :masked]
   acts_as_enum :map_type, [:index, :is_map, :not_map ]
   acts_as_enum :rough_state, [:step_1, :step_2, :step_3, :step_4]
   default_values :status => :unloaded, :mask_status => :unmasked, :map_type => :is_map, :rough_state => :step_1

   named_scope :warped, :conditions => {:status => [Map.status(:warped), Map.status(:published)], :map_type => Map.map_type(:is_map) }
   named_scope :published, :conditions => {:status => Map.status(:published), :map_type => Map.map_type(:is_map)}

   named_scope :real_maps, :conditions => {:map_type => Map.map_type(:is_map)}
   attr_accessor :error
   validates_numericality_of :rough_lat, :rough_lon, :rough_zoom, :allow_nil => true

   after_destroy :delete_images, :update_counter_cache, :update_layers
   after_save :update_counter_cache

   def self.map_type_hash
     values = Map::MAP_TYPE
     keys = ["Index/Overview", "Is a map", "Not a map"]
     Hash[*keys.zip(values).flatten]
   end


   def maps_dir
      "/var/lib/maps/src"
   end

   def dest_dir
      "/var/lib/maps/dest"
   end

   def warped_dir
      dest_dir
   end

   def warped_filename
      File.join(warped_dir, id.to_s) + ".tif"
   end

   def warped_png_dir
     File.join(dest_dir, "/png/")
   end
   
   def warped_png
     unless File.exists?(warped_png_filename)
       convert_to_png
     end
     warped_png_filename
   end

   def warped_png_filename
     filename =  File.join(warped_png_dir, id.to_s) + ".png"
   end

   def warped_png_aux_xml
     warped_png + ".aux.xml"
   end

   def mask_file_format
      "gml"
   end

   def temp_filename
      # self.full_filename  + "_temp"
      File.join(warped_dir, id.to_s) + "_temp"
   end

   def masking_file
      File.join("/var/www/apps/shared/masks/",  self.id.to_s) + ".json"
   end

   def masking_file_gml
      File.join("/var/www/apps/shared/masks/",  self.id.to_s) + ".gml"
   end

   def masked_src_filename
      self.filename + "_masked"
   end


   #do we want to delete src image when model is deleted?
   def delete_images
      logger.info "deleting images"

      if File.exists?(self.temp_filename)
         logger.info "deleted temp"
         File.delete(self.temp_filename)
      end

      if File.exists?(self.warped_filename)
         logger.info "deleted warped"
         File.delete(self.warped_filename)
      end

      if File.exists?(self.warped_png_filename)
        logger.info "deleted warped png too"
        File.delete(self.warped_png_filename)
      end

   end

   def update_counter_cache
     logger.info "update_counter_cache"
     unless self.layers.empty?
       self.layers.each do |layer|
         layer.update_counts
       end
     end
   end

   def update_layers
     logger.info "updating (visible) layers"
     unless self.layers.visible.empty?
       self.layers.visible.each  do |layer|
         layer.update_layer
       end
     end
   end
   
   #method to publish the map
   #sets status to published
   def publish
     self.status = :published
     self.save
   end

   #unpublishes a map, sets it's status to warped
   def unpublish
     self.status = :warped
     self.save
   end


   def update_map_type(map_type)
     if Map::MAP_TYPE.include? map_type.to_sym
       self.update_attributes(:map_type => map_type.to_sym)
       self.update_layers
     end
   end

   def last_changed
     if self.gcps.size > 0
       self.gcps.last.created_at > self.updated_at ? self.gcps.last.created_at : self.updated_at
     else
       self.updated_at
     end
  end

   def update_gcp_touched_at
      self.touch(:gcp_touched_at) 
   end

   def save_rough_centroid(lon,lat)
    self.rough_centroid =  Point.from_lon_lat(lon,lat)
    self.save
   end

   #Layer.with_year orders by size
   #can return nil if there is no year
   def depicts_year
     self.layers.with_year.collect(&:depicts_year).compact.first
   end


   #attempts to align based on the extent and offset of the 
   #reference map's warped image
   #results it nicer gpcs to edit with later
   def align_with_warped (srcmap, align = nil, append = false)
      srcmap = Map.find(srcmap)
      origgcps = srcmap.gcps.hard

      #clear out original gcps, unless we want to append the copied gcps to the existing ones
      self.gcps.hard.destroy_all unless append == true

      #extent of source from gdalinfo
      stdin, stdout, sterr = Open3::popen3("gdalinfo #{srcmap.warped_filename}")
      info = stdout.readlines.to_s
      stringLW,west,south = info.match(/Lower Left\s+\(\s*([-.\d]+), \s+([-.\d]+)/).to_a
      stringUR,east,north = info.match(/Upper Right\s+\(\s*([-.\d]+), \s+([-.\d]+)/).to_a

      lon_shift = west.to_f - east.to_f
      lat_shift = south.to_f - north.to_f

      origgcps.each do |gcp|
         a = Gcp.new()
         a = gcp.clone
         if align == "east"
            a.lon -= lon_shift
         elsif align == "west"
            a.lon += lon_shift
         elsif align == "north"
            a.lat -= lat_shift
         elsif align == "south"
            a.lat += lat_shift
         else
            #if no align, then dont change the gcps
         end
         a.map = self
         a.save
      end

      newgcps = self.gcps.hard
   end

   #attempts to align based on the width and height of 
   #reference map's un warped image
   #results it potential better fit than align_with_warped
   #but with less accessible gpcs to edit
   def align_with_original(srcmap, align = nil, append = false)
      srcmap = Map.find(srcmap)
      origgcps = srcmap.gcps.hard

      #clear out original gcps, unless we want to append the copied gcps to the existing ones
      self.gcps.hard.destroy_all unless append == true
       
      origgcps.each do |gcp|
         new_gcp = Gcp.new()
         new_gcp = gcp.clone
         if align == "east"
             new_gcp.x -= srcmap.width
           
         elsif align == "west"
            new_gcp.x += srcmap.width
         elsif align == "north"
            new_gcp.y += srcmap.height
         elsif align == "south"
            new_gcp.y -= srcmap.height
         else
            #if no align, then dont change the gcps
         end
         new_gcp.map = self
         new_gcp.save
      end

      newgcps = self.gcps.hard
   end


   def bounds
      return bbox if bbox and not bbox.empty?
      x_array = []
      y_array = []

      self.gcps.hard.each do |gcp|
         #logger.info "GCP lat #{gcp[:lat]} , lon #{gcp[:lon]} "
         x_array << gcp[:lat]
         y_array << gcp[:lon]

      end
      our_bounds = [y_array.min ,x_array.min ,y_array.max, x_array.max].join ','
      #logger.info "bounds= #{our_bounds.to_s}"
      #our_bounds
   end
    
   #returns a GeoRuby polygon object representing the bounds
   def bounds_polygon
      bounds_float  = bounds.split(',').collect {|i| i.to_f}
      Polygon.from_coordinates([ [bounds_float[0..1]] , [bounds_float[2..3]] ])
   end
    
   #tiny helper module for ruby min and max used when calculating rms transformation error
   module Math_my
      def self.min(a,b)
         a <= b ? a : b
      end

      def self.max(a,b)
         a >= b ? a : b
      end
   end

   # mapscan gets error attibute set and gcps get error attribute set
   # not saved to db, though.
   #
   # ported to ruby by chippy and based on bsd licenced code  
   #  from oldmapsonline.org Klokan Petr Pridal (python) & Bernhard Jenny (Java) from mapanalyst project (gpl2)
   def gcps_with_error(soft=nil)
    unless soft == 'true'
      gcps = Gcp.hard.find(:all, :conditions =>["mapscan_id = ?", self.id], :order => 'created_at')
    else
      gcps = Gcp.soft.find(:all, :conditions =>["mapscan_id = ?", self.id], :order => 'created_at')
    end
      

      if gcps.size > 3

        begin 

         destSet = Array.new
         sourceSet = Array.new

         gcps.each do |gcp|
            destSet << [gcp.x, gcp.y]
            sourceSet << [gcp.lon, gcp.lat]

            #  gcp.x.to_s + " "+ gcp.y.to_s + " "+ gcp.lon.to_s + " "+ gcp.lat.to_s
         end

         numberOfPoints = Math_my.min( destSet.size ,sourceSet.size)

         cxDst, cyDst, cxSrc, cySrc = 0,0,0,0

         0.upto(numberOfPoints-1) do  | i |
            cxDst += destSet[i][0]
            cyDst += destSet[i][1]
            cxSrc += sourceSet[i][0]
            cySrc += sourceSet[i][1]
         end

         cxDst /= numberOfPoints
         cyDst /= numberOfPoints
         cxSrc /= numberOfPoints
         cySrc /= numberOfPoints

         x = Matrix[* destSet.map { |dst| [dst[0] - cxDst] } ].transpose
         y = Matrix[* destSet.map { |dst| [dst[1] - cyDst] } ].transpose
         aa = Matrix[* sourceSet.map { |src| [1.0, src[0]-cxSrc, src[1]-cySrc] } ]
         at = aa.transpose

         q = (at * aa).inverse
         a = q * (at * x.transpose)
         b = q * (at * y.transpose)

         a1 = a[1,0]
         a2 = a[2,0]
         a3 = b[1,0]
         a4 = b[2,0]

         w = [a1, a3, a2, a4, cxDst - a1*cxSrc - a2*cySrc, cyDst - a3*cxSrc - a4*cySrc ]
         projSet = Array.new
         sourceSet.each do |x,y|
            p = Array.new
            p << ( w[4] + w[0]*x + w[2]*y )
            p << ( w[5] + w[1]*x + w[3]*y )
            projSet << p
         end

         errs = Array.new

         0.upto(destSet.size-1) do  | i |

            x,y = destSet[i]
            px,py = projSet[i]
            minx = Math_my.min( x, px)
            maxx = Math_my.max( x, px)
            miny = Math_my.min( y, py)
            maxy = Math_my.max( y, py)
            sx = maxx - minx
            sy = maxy - miny
            err = Math.sqrt( sx*sx + sy*sy )
            errs << err
            #error for gcp
            #puts err
         end
         #now get sqrt for all

         sqerrs = errs.map{|err| err*err }
         sumerrs = sqerrs.inject(0) { |s,v| s += v }

         rmse = Math.sqrt( sumerrs / errs.size)
         # puts "RMSE = " +rmse.inspect

         count = 0
         gcps.each do |gcp|
            #error for gcp
            gcp.error = errs[count]
            count += 1
         end
         @error = rmse #rms error for map
        rescue ExceptionForMatrix::ErrNotRegular => whoops
          logger.info "error in matrix: " + whoops
          gcps.each do |gcp|
            gcp.error = 0.0
          end
          @error = 0.0

        end
      else
         logger.info "not enough gcps for calc"
         gcps.each do |gcp|
            gcp.error = 0.0
         end
         #not enough or no gcps to do calculation
         @error = 0.0
      end
      #send back the gpcs with error calculation
      gcps
   end



   def available?
      return [:available,:warping,:warped, :published].include?(status)
   end

   def published?
    status == :published
   end

   def warped_or_published?
     return [:warped, :published].include?(status)
   end

   def fetch_from_image_server(force = false)
      return if available? and not force
      if not available?
         self.height       = 0
         self.width        = 0
         self.filename     = ''
         self.status       = :loading
         logger.debug "saving if not available"
         self.save!
      end
      
      #to work with new nypl repo / digital archive
      id = self.bibl_uuid 
      url = NyplRepo.get_highreslink(id, self.nypl_digital_id.upcase)

      #id = self.nypl_digital_id
      #command = "#{RAILS_ROOT}/bin/fetch.sh #{id} #{maps_dir}"
      command = "#{RAILS_ROOT}/bin/fetch_repo.sh #{id} #{url} #{maps_dir}"
      logger.debug command
      
      if url
        f_in, f_out, f_err = Open3::popen3(command)

        logger.info "fetch exit status etc ="+ $?.inspect
        f_err_msg = f_err.readlines.to_s
        logger.debug "err msg: "+ f_err_msg
      end

      if url && $?.exitstatus == 0 && !f_err_msg.include?("ERROR")
         filename = File.join(maps_dir, id) + ".tif"
         img = Magick::Image.ping(filename)
         self.height       = img[0].rows
         self.width        = img[0].columns
         self.filename     = filename
         self.status       = :available if not available?
      elsif not available?
        if f_err_msg
         logger.error "fetch std error =" + f_err_msg
        end
         self.status       = :unloaded
      end
      #logger.debug [self.height, self.width, self.filename, self.status]
      logger.debug "now saving after"
      self.save!
      
      return $?.exitstatus == 0 ? true : false
   end

   def mask!

      self.mask_status = :masking
      save!
      format = self.mask_file_format

      if format == "gml"
         return "no masking file found, have you created a clipping mask and saved it?"  if !File.exists?(masking_file_gml)
         masking_file = self.masking_file_gml
         layer = "features"
      elsif format == "json"
         return "no masking file found, have you created a clipping mask and saved it?"  if !File.exists?(masking_file_json)
         masking_file = self.masking_file_json
         layer = "OGRGeoJson"
      else
         return "no masking file matching specified format found."
      end

      masked_src_filename = self.masked_src_filename
      if File.exists?(masked_src_filename)
         #deleting old masked image
         File.delete(masked_src_filename)
      end
      #copy over orig to a new unmasked file
      File.copy(filename, masked_src_filename)
      #TODO ADD -i switch when we have newer gdal
      require 'open3'
      r_stdin, r_stdout, r_stderr = Open3::popen3(
      "gdal_rasterize -i -burn 17 -b 1 -b 2 -b 3 #{masking_file} -l #{layer} #{masked_src_filename}"
      )
      logger.info "gdal_rasterize -i -burn 17 -b 1 -b 2 -b 3 #{masking_file} -l #{layer} #{masked_src_filename}"
      r_out  = r_stdout.readlines.to_s
      r_err = r_stderr.readlines.to_s

      #if there is an error, and it's not a warning about SRS 
      if r_err.size > 0 && r_err.split[0] != "Warning"
         #error, need to fail nicely
         logger.error "ERROR gdal rasterize script: "+ r_err
         logger.error "Output = " +r_out
         r_out = "ERROR with gdal rasterise script: " + r_err + "<br /> You may want to try it again? <br />" + r_out

      else
 
        r_out = "Success! Map was cropped!"
      end

      self.mask_status = :masked
      save!
      r_out
   end

   # gdal_rasterize -i -burn 17 -b 1 -b 2 -b 3 SSS.json -l OGRGeoJson orig.tif
   # gdal_rasterize -burn 17 -b 1 -b 2 -b 3 SSS.gml -l features orig.tif


   ##warp method without masking

   def warp!(resample_option, transform_option, use_mask="false")
      prior_status = self.status
      self.status = :warping
      save!

      gcp_array = self.gcps.hard

      gcp_string = ""

      gcp_array.each do |gcp|
         gcp_string = gcp_string + gcp.gdal_string
      end

      mask_options = ""
      if use_mask == "true" && self.mask_status == :masked
         src_filename = self.masked_src_filename
         mask_options = " -srcnodata '17 17 17' "
      else
         src_filename = self.filename
      end

      dest_filename = self.warped_filename
      temp_filename = self.temp_filename

      #delete existing temp images @map.delete_images
      if File.exists?(dest_filename)
         #logger.info "deleted warped file ahead of making new one"
         File.delete(dest_filename)
      end

      logger.info "gdal translate"

      t_stdin, t_stdout, t_stderr = Open3::popen3(
      "gdal_translate -a_srs '+init=epsg:4326' -of VRT #{src_filename} #{temp_filename}.vrt #{gcp_string}"
      )

      logger.info "gdal_translate -a_srs '+init=epsg:4326' -of VRT #{src_filename} #{temp_filename}.vrt #{gcp_string}"
      t_out  = t_stdout.readlines.to_s
      t_err = t_stderr.readlines.to_s

      if t_err.size > 0
         logger.error "ERROR gdal translate script: "+ t_err
         logger.error "Output = " +t_out
         t_out = "ERROR with gdal translate script: " + t_err + "<br /> You may want to try it again? <br />" + t_out
      else
         t_out = "Okay, translate command ran fine! <div id = 'scriptout'>" + t_out + "</div>"
      end
      trans_output = t_out

      #check for colorinterop=pal ? -disnodata 255 or -dstalpha
      command = "gdalwarp #{transform_option}  #{resample_option} -dstalpha #{mask_options} -s_srs 'EPSG:4326' #{temp_filename}.vrt #{dest_filename} -co TILED=YES -co COMPRESS=JPEG -co JPEG_QUALITY=85"
      w_stdin, w_stdout, w_stderr = Open3::popen3(command)
      logger.info command

      w_out = w_stdout.readlines.to_s
      w_err = w_stderr.readlines.to_s
      if w_err.size > 0
         logger.error "Error gdal warp script" + w_err
         logger.error "output = "+w_out
         w_out = "error with gdal warp: "+ w_err +"<br /> try it again?<br />"+ w_out
      else
         w_out = "Okay, warp command ran fine! <div id='scriptout'>" + w_out +"</div>"
      end
      warp_output = w_out

      # gdaladdo

      command = "gdaladdo -r average #{dest_filename} 2 4 8 16 32 64"
      o_stdin, o_stdout, o_stderr = Open3::popen3(command)
      logger.info command

      o_out = o_stdout.readlines.to_s
      o_err = o_stderr.readlines.to_s
      if o_err.size > 0
         logger.error "Error gdal overview script" + o_err
         logger.error "output = "+o_out
         o_out = "error with gdal overview: "+ o_err +"<br /> try it again?<br />"+ o_out
      else
         o_out = "Okay, overview command ran fine! <div id='scriptout'>" + o_out +"</div>"
      end
      overview_output = o_out

      if File.exists?(temp_filename + '.vrt')
         logger.info "deleted temp vrt file"
         File.delete(temp_filename + '.vrt')
      end

      # don't care too much if overviews threw a random warning
      if w_err.size <= 0 and t_err.size <= 0
         if prior_status == :published
           self.status = :published
         else 
           self.status = :warped
         end
         spawn do 
           convert_to_png
         end
         self.touch(:rectified_at)
      else
         self.status = :available
      end
      save!
      update_layers
      update_bbox
      output = "Step 1: Translate: "+ trans_output + "<br />Step 2: Warp: " + warp_output + \
               "Step 3: Add overviews:" + overview_output
   end

   require 'gdalinfo'
   def update_bbox
  
     if File.exists? self.warped_filename
       logger.info "updating bbox..."
      begin
        extents = get_raster_extents self.warped_filename
        self.bbox = extents.join ","
        logger.debug "SAVING BBOX GEOM"
        poly_array = [ 
          [ extents[0], extents[1] ],
          [ extents[2], extents[1] ],
          [ extents[2], extents[3] ], 
          [ extents[0], extents[3] ],
          [ extents[0], extents[1] ]
        ]
        self.bbox_geom = Polygon.from_coordinates([poly_array])
        save
      rescue
      end
     end
   end

   def delete_mask
      logger.info "delete mask"
      if File.exists?(self.masking_file_gml)
         File.delete(self.masking_file_gml)
      end
      if File.exists?(self.masking_file_gml+".ol")
         File.delete(self.masking_file_gml+".ol")
      end

      self.mask_status = :unmasked
      save!
      "mask deleted"
   end


   def save_mask(vector_features)
      if self.mask_file_format == "gml"
         msg = save_mask_gml(vector_features)
      elsif self.mask_file_format == "json"
         msg = save_mask_json(vector_features)
      else
         msg = "Mask format unknown"
      end
      msg
   end


   #parses geometry from openlayers, and saves it to file.
   #GML format
   def save_mask_gml(features)
      if File.exists?(self.masking_file_gml)
         File.delete(self.masking_file_gml)
      end
      if File.exists?(self.masking_file_gml+".ol")
         File.delete(self.masking_file_gml+".ol")
      end
      origfile = File.new(self.masking_file_gml+".ol", "w+")
      origfile.puts(features)
      origfile.close

      doc = REXML::Document.new features
      REXML::XPath.each( doc, "//gml:coordinates") { | element|
         # blimey element.text.split(' ').map {|i| i.split(',')}.map{ |i| i[0] => i[1]}.inject({}){|i,j| i.merge(j)}
         coords_array = element.text.split(' ')
         new_coords_array = Array.new
         coords_array.each do |coordpair|
            coord = coordpair.split(',')
            coord[1] = self.height - coord[1].to_f
            newcoord = coord.join(',')
            new_coords_array << newcoord
         end
         element.text = new_coords_array.join(' ')

      } #element
      gmlfile = File.new(self.masking_file_gml, "w+")
      doc.write(gmlfile)
      gmlfile.close
      message = "Map clipping mask saved (gml)"
   end

   #parses geometry from openlayers, and saves it to file.
   #JSON format
   def save_mask_json(features)
      if File.exists?(self.masking_file_json)
         File.delete(self.masking_file_json)
      end

      image_height = self.height
      json = ActiveSupport::JSON.decode(features)
      message = "Nothing saved, something may have gone wrong"
      if json["features"].length <= 0
         message = "Nothing saved, you have to draw a polygon on the map first"
      else
         json["features"].each do |feature|
            coords = feature["geometry"]["coordinates"]
            coords[0].each do |coord|
               # x = coord[0]
               coord[1] = image_height - coord[1]
            end
         end
         new_json = ActiveSupport::JSON.encode(json)
         jsonfile = File.new(self.masking_file, "w+")
         jsonfile.puts new_json
         jsonfile.close
         message = "Map clipping mask saved"
      end
      message
   end

   def convert_to_png
     logger.info "start convert to png ->  #{warped_png_filename}"
     ext_command = "gdal_translate -of png #{warped_filename} #{warped_png_filename}"
     stdin, stdout, stderr = Open3::popen3(ext_command)
     logger.debug ext_command
     if stderr.readlines.to_s.size > 0
       logger.error "ERROR convert png #{warped_filename} -> #{warped_png_filename}"
       logger.error stderr.readlines.to_s
       logger.error stdout.readlines.to_s
     else
       logger.info "end, converted to png -> #{warped_png_filename}"
     end
   end
   
   #uses Yahoo Geo placemaker to get the places mentioned in the title and description
   #it will also get a sibling map, if that has been rectified, to help determine appropriate zoom scale
   #TODO - weight the results to bias the text in the title, and experiment with the focusWoeid
   def find_bestguess_places
     url = URI.parse('http://wherein.yahooapis.com/v1/document')
     appid = Yahoo_app_id
     builder = Nokogiri::XML::Builder.new do |xml|
       xml.root {
         xml.title {
           xml.text self.title.to_s
         }
         xml.description {
           xml.text self.description.to_s
         }
       }
     end
     documentContent = builder.to_xml
     documentType = "text/xml"
     focusWoeid = 2459115  #focus to new york
     post_args = {
    #'focusWoeid' => focusWoeid,
    'appid' => appid,
    'documentContent' => documentContent,
    'documentType' => documentType 
     }
     begin 
       resp, data = Net::HTTP.post_form(url, post_args)

       @newresults = Nokogiri::XML.parse(data)
       xmlroot = @newresults.root
       if xmlroot.at('document') && xmlroot.at('document').children.size > 1
         south_west = [xmlroot.at('document > extents > southWest > longitude').children[0].text,
           xmlroot.at('document > extents > southWest > latitude').children[0].text]
         north_east = [xmlroot.at('document > extents > northEast > longitude').children[0].text,
           xmlroot.at('document > extents > northEast > latitude').children[0].text]
         extents = [south_west + north_east].join ',' 

         places = Array.new
         place_woeids = Array.new
         place_count = 0
         xmlroot.xpath('/xmlns:contentlocation/xmlns:document/xmlns:placeDetails/xmlns:place').each do | place |
           place_hash = Hash.new
           place_hash[:name] = place.at('name').children[0].text
           place_hash[:lon] = place.at('centroid > longitude').children[0].text
           place_hash[:lat] = place.at('centroid > latitude').children[0].text
         places << place_hash
           place_woeids << place.at('woeId').children[0].text
         place_count += 1
         end

         if !self.layers.visible.empty? && !self.layers.visible.first.maps.warped.empty?
           sibling_extent = self.layers.visible.first.maps.warped.last.bbox
         else
           sibling_extent = nil
         end
         top_places = Array.new

         xmlroot.xpath('/xmlns:contentlocation/xmlns:document/xmlns:referenceList/xmlns:reference').each do | reference |
           if "/root[1]/title[1]" ==  reference.at('xpath').children[0].text
             ref_woeid =  reference.at('woeIds').children[0].text.split.first
              if place_woeids.include? ref_woeid
                top_places <<  places[place_woeids.index(ref_woeid)]
              end
            end
         end

         temp_a = places - top_places
         places = top_places + temp_a
         placemaker_result = {:status => "ok", :map_id => self.id, :extents => extents, :count => place_count, :places => places, :sibling_extent=> sibling_extent}

       else
         placemaker_result = {:status => "fail", :code => "no results"}
       end


     rescue SocketError => e
       logger.error "Socket error in find bestguess places" + e.to_s
       placemaker_result = {:status => "fail", :code => "socketError"}
     end
     placemaker_result
   end


end
