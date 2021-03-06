class LayersController < ApplicationController
  layout 'layerdetail', :only => [:show,  :edit, :export, :metadata]
  before_filter :authenticate_user! , :except => [:wms, :wms2, :show_kml, :show, :index, :metadata, :maps, :thumb, :geosearch, :comments, :tile, :export]
  before_filter :check_administrator_role, :only => [:publish, :toggle_visibility, :merge, :trace, :id, :remove_map, :update_year]

  before_filter :find_layer, :only => [:show, :export, :metadata, :toggle_visibility, :update_year, :publish, :remove_map, :merge, :maps, :thumb, :comments, :trace, :id, :digitize]
  before_filter :check_if_layer_is_editable, :only => [:edit, :update, :remove_map, :update_year, :update, :destroy]

  skip_before_filter :check_site_read_only, :only => [:show, :index, :metadata, :maps, :thumb, :geosearch, :comments, :tile, :wms, :wms2, :export]

  rescue_from ActiveRecord::RecordNotFound, :with => :bad_record
  helper :sort
  include SortHelper

  def comments
    @html_title = "comments"
    @selected_tab = 5
    @current_tab = "comments"
    @comments = @layer.comments
    choose_layout_if_ajax
    respond_to do | format |
      format.html {}
    end
  end


  def thumb
    redirect_to @layer.thumb
  end


  def geosearch
    require 'geoplanet'
    sort_init 'updated_at'
    sort_update

    extents = [-74.1710,40.5883,-73.4809,40.8485] #NYC

    #TODO change to straight javascript call.
    if params[:place] && !params[:place].blank?
      place_query = params[:place]
      GeoPlanet.appid = APP_CONFIG['yahoo_app_id']

      geoplanet_result = GeoPlanet::Place.search(place_query, :count => 2)
      if geoplanet_result[0]
        g_bbox =  geoplanet_result[0].bounding_box.map!{|x| x.reverse}
        extents = g_bbox[1] + g_bbox[0]
        render :json => extents.to_json
        return
      else
        render :json => extents.to_json
        return
      end
    end

    if params[:bbox] && params[:bbox].split(',').size == 4
      begin
        extents = params[:bbox].split(',').collect {|i| Float(i)}
      rescue ArgumentError
        logger.debug "arg error with bbox, setting extent to defaults"
      end
    end
    @bbox = extents.join(',')
    if extents
      bbox_poly_ary = [
        [ extents[0], extents[1] ],
        [ extents[2], extents[1] ],
        [ extents[2], extents[3] ],
        [ extents[0], extents[3] ],
        [ extents[0], extents[1] ]
      ]

      map_srid = 0
      map_srid = Map.warped.first.bbox_geom.srid if Map.warped.first && Map.warped.first.bbox_geom
      if map_srid == 0
        bbox_polygon = GeoRuby::SimpleFeatures::Polygon.from_coordinates([bbox_poly_ary]).as_wkt
      else
        bbox_polygon = GeoRuby::SimpleFeatures::Polygon.from_coordinates([bbox_poly_ary]).as_ewkt
      end

      if params[:operation] == "within"
        conditions = ["ST_Within(bbox_geom, ST_GeomFromText('#{bbox_polygon}'))"]
      else
        conditions = ["ST_Intersects(bbox_geom, ST_GeomFromText('#{bbox_polygon}'))"]
      end

    else
      conditions = nil
    end


    if params[:sort_order] && params[:sort_order] == "desc"
      sort_nulls = " NULLS LAST"
    else
      sort_nulls = " NULLS FIRST"
    end
    @operation = params[:operation]

    if @operation == "intersect"
      sort_geo = "ABS(ST_Area(bbox_geom) - ST_Area(ST_GeomFromText('#{bbox_polygon}'))) ASC,  "
    else
      sort_geo ="ST_Area(bbox_geom) DESC ,"
    end

    @year_min = Map.minimum(:issue_year) - 1
    @year_max = Map.maximum(:issue_year) + 1

    year_conditions = nil
    if params[:from] && params[:to] && !(@year_min == params[:from].to_i && @year_max == params[:to].to_i)
      year_conditions = {:depicts_year => params[:from].to_i..params[:to].to_i}
    end

    paginate_params = {
      :page => params[:page],
      :per_page => 20
    }
    order_params = sort_geo + sort_clause + sort_nulls
    @layers = Layer.select("bbox, name, updated_at, id, maps_count, rectified_maps_count,
                       depicts_year").visible.with_maps.where(conditions).where(year_conditions).paginate(paginate_params)

    @jsonlayers = @layers.to_json
    respond_to do |format|
      format.html{ render :layout =>'application' }
      format.json { render :json => {:stat => "ok",
          :current_page => @layers.current_page,
          :per_page => @layers.per_page,
          :total_entries => @layers.total_entries,
          :total_pages => @layers.total_pages,
          :items => @layers.to_a}.to_json , :callback => params[:callback]}
    end
  end



  def index
    sort_init('created_at', {:default_order => "desc"})
    session[@sort_name] = nil  #remove the session sort as we have percent
    sort_update
    @query = params[:query]
    @field = %w(text name description catnyp uuid).detect{|f| f== (params[:field])}


    @field = "text" if @field.nil?
    where_col = @field

    if  @field == "text"
      where_col  = "(name || ' ' || description)"
    end


    if @query && @query != "null" #null will be set by pagless js if theres no query
      conditions =   ["#{where_col}  ~* ?", '(:punct:|^|)'+@query+'([^A-z]|$)']
    else
      conditions = nil
    end
    if params[:sort_key] == "percent"
      select = "*, round(rectified_maps_count::float / maps_count::float * 100) as percent"
      conditions.nil? ? conditions = ["maps_count > 0"] : conditions.add_condition('maps_count > 0')
    else
      select = "*"
    end

    @year_min = Map.minimum(:issue_year).to_i - 1
    @year_max = Map.maximum(:issue_year).to_i + 1

    year_conditions = nil
    if params[:from] && params[:to] && !(@year_min == params[:from].to_i && @year_max == params[:to].to_i)
      year_conditions = {:depicts_year => params[:from].to_i..params[:to].to_i}
    end

    @from = params[:from]
    @to = params[:to]


    if params[:sort_order] && params[:sort_order] == "desc"
      sort_nulls = " NULLS LAST"
    else
      sort_nulls = " NULLS FIRST"
    end

    @per_page = params[:per_page] || 50
    paginate_params = {
      :page => params[:page],
      :per_page => @per_page
    }

    order_options =  sort_clause  + sort_nulls

    map = params[:map_id]
    if !map.nil?
      @map = Map.find(map)

      if @map.versions.last
        @current_version_number = @map.versions.last.index
        @current_version_user = User.find_by_id(@map.versions.last.whodunnit.to_i)
      else
        @current_version_number = 1
        @current_version_user = nil
      end

    @version_users = PaperTrail::Version.where({:item_type => 'Map', :item_id => @map.id}).where.not(:whodunnit => nil).where.not(:whodunnit => @current_version_user).select(:whodunnit).distinct.limit(6)

      layer_ids = @map.layers.map(&:id)
      @layers = Layer.where(id: layer_ids).where(conditions).select('*, round(rectified_maps_count::float / maps_count::float * 100) as percent').where(conditions).order(order_options).paginate(paginate_params)
      @html_title = "Layer List for Map #{@map.id}"
      @page = "for_map"
    else
      @layers = Layer.select(select).where(conditions).where(year_conditions).order(sort_clause + sort_nulls).paginate(paginate_params)
      @html_title = "Browse Layer List"
    end

    if request.xhr?
      # for pageless :
      # #render :partial => 'layer', :collection => @layers
      render :action => 'index.rjs'
    else
      respond_to do |format|
        format.html {render :layout => "application"}

        format.xml { render :xml => @layers.to_xml(:root => "layers", :except => [:uuid, :parent_uuid, :description]) {|xml|
            xml.tag!'total-entries', @layers.total_entries
            xml.tag!'per-page', @layers.per_page
            xml.tag!'current-page',@layers.current_page}
        }
        format.json {render :json => {:stat => "ok", :items => @layers.to_a}.to_json(:except => [:uuid, :parent_uuid, :description]), :callback => params[:callback] }
      end
    end
  end


  #method returns json or xml representation of a layers maps
  def maps
    paginate_params = {
      :page => params[:page],
      :per_page => 50
    }

    show_warped = params[:show_warped]
    unless show_warped == "0"
      lmaps = @layer.maps.warped.order(:map_type).paginate(paginate_params)
    else
      lmaps = @layer.maps.order(:map_type).paginate(paginate_params)
    end
    respond_to do |format|
      #format.json {render :json =>lmaps.to_json(:stat => "ok",:except => [:content_type, :size, :bbox_geom, :uuid, :parent_uuid, :filename, :parent_id,  :map, :thumbnail])}
      format.json {render :json =>{:stat => "ok",
          :current_page => lmaps.current_page,
          :per_page => lmaps.per_page,
          :total_entries => lmaps.total_entries,
          :total_pages => lmaps.total_pages,
          :items => lmaps.to_a}.to_json(:except => [:content_type, :size, :bbox_geom, :uuid, :parent_uuid, :filename, :parent_id,  :map, :thumbnail]), :callback => params[:callback] }

      format.xml {render :xml => lmaps.to_xml(:root => "maps",:except => [:content_type, :size, :bbox_geom, :uuid, :parent_uuid, :filename, :parent_id,  :map, :thumbnail])  {|xml|
          xml.tag!'total-entries', lmaps.total_entries
          xml.tag!'per-page', lmaps.per_page
          xml.tag!'current-page',lmaps.current_page} }
    end
  end

  def show
    @current_tab = "show"
    @selected_tab = 0
    @disabled_tabs =  []
    unless @layer.rectified_maps_count > 0 #i.e. if the layer has no maps, then dont let people  export
      @disabled_tabs = ["digitize"]
    end

    @maps = @layer.maps.order(:map_type).paginate(:page => params[:page], :per_page => 30)

    @html_title = "Layer "+ @layer.id.to_s + " " + @layer.name.to_s

    if request.xhr?
      unless params[:page]
        @xhr_flag = "xhr"
        render :action => "show", :layout => "layer_tab_container"
      else
        render :action =>  "show_maps.rjs"
      end
    else
      respond_to do |format|
        format.html {render :layout => "layerdetail"}# show.html.erb
        #format.json {render :json => @layer.to_json(:except => [:uuid, :parent_uuid, :description])}
        format.json {render :json => {:stat => "ok", :items => @layer}.to_json(:except => [:uuid, :parent_uuid, :description]), :callback => params[:callback] }

        format.kml {render :action => "show_kml", :layout => false}
      end
    end
  end




  def export
    @current_tab = "export"
    @selected_tab = 3

    @html_title = "Export Layer "+ @layer.id.to_s
    if request.xhr?
      @xhr_flag = "xhr"
      render :layout => "layer_tab_container"
    else
      respond_to do |format|
        format.html {render :layout => "layerdetail"}
      end
    end
  end

  def metadata
    @current_tab = "metadata"
    @selected_tab = 4
    @layer_properties = @layer.layer_properties

    choose_layout_if_ajax
  end


  #ajax method
  def toggle_visibility
    @layer.is_visible = !@layer.is_visible
    @layer.save
    @layer.update_layer
    if @layer.is_visible
      update_text = "(Visible)"
    else
      update_text = "(Not Visible)"
    end
    render :json => {:message => update_text}
  end

  def update_year
    @layer.update_attributes(params[:layer].permit(:depicts_year))
    render :json => {:message => "Depicts : " + @layer.depicts_year.to_s }
  end

  #merge this layer with another one
  #moves all child object to new parent
  def merge
    if request.get?
      #just show form
      render :layout => 'application'
    elsif request.put?
      @dest_layer = Layer.find(params[:dest_id])
      #TODO uncomment following line to enable this
      #@layer.merge(@dest_layer.id)
      render :text  => "Layer has been merged into new layer - all maps copied across! (functionality disabled at the moment)"
    end
  end


  def remove_map
    @map = Map.find(params[:map_id])

    @layer.remove_map(@map.id)
    render :text =>  "Dummy text - Map removed from this layer "
  end

  def publish
    if @layer.rectified_percent < 100
       flash[:notice] =  "Layer has less than 100% of its maps rectified, and cannot be published."
    else
      @layer.publish
      flash[:notice] = "Layer will be published and tiles transfered via tilestache. Please wait."
    end
    redirect_to @layer
  end


  def trace
    redirect_to layer_path unless @layer.is_visible? && @layer.rectified_maps_count > 0
    @overlay = @layer
    render "maps/trace", :layout => "application"
  end

  def id
    redirect_to layer_path unless @layer.is_visible? && @layer.rectified_maps_count > 0
    @overlay = @layer
    render "maps/id", :layout => false
  end

  # called by id JS oauth
  def idland
    render "maps/idland", :layout => false
  end


  def digitize
    @current_tab = "digitize"
    @selected_tab = 1
    @html_title = "Digitizing Layer "+ @layer.id.to_s

    if request.xhr?
      @xhr_flag = "xhr"
      render :action => "digitize", :layout => "tab_container"
    else
      if @layer.rectified_maps_count > 0
        respond_to do |format|
          format.html {render :layout => "layerdetail"}
        end
      else
        redirect_to :action => 'show'
      end
    end

  end

  require 'mapscript'
  include Mapscript
  def wms()
    begin
      @layer = Layer.find(params[:id])
      ows = Mapscript::OWSRequest.new

      ok_params = Hash.new
      # params.each {|k,v| k.upcase! } frozen string error

      params.each {|k,v| ok_params[k.upcase] = v }

      [:request, :version, :transparency, :service, :srs, :width, :height, :bbox, :format, :srs].each do |key|

        ows.setParameter(key.to_s, ok_params[key.to_s.upcase]) unless ok_params[key.to_s.upcase].nil?
      end

      ows.setParameter("VeRsIoN","1.1.1")
      ows.setParameter("STYLES", "")
      ows.setParameter("LAYERS", "image")
      #ows.setParameter("COVERAGE", "image")

      map = Mapscript::MapObj.new(File.join(Rails.root, '/lib/mapserver/wms.map'))
      projfile = File.join(Rails.root, '/lib/proj')
      map.setConfigOption("PROJ_LIB", projfile)
      #map.setProjection("init=epsg:900913")
      map.applyConfigOptions

      rel_url_root =  (ActionController::Base.relative_url_root.blank?)? '' : ActionController::Base.relative_url_root
      map.setMetaData("wms_onlineresource",
        "http://" + request.host_with_port  + rel_url_root + "/layers/wms/#{@layer.id}")

      raster = Mapscript::LayerObj.new(map)
      raster.name = "image"
      raster.type =  Mapscript::MS_LAYER_RASTER
      raster.addProcessing("RESAMPLE=BILINEAR")
      raster.tileindex = @layer.tileindex_path
      raster.tileitem = "Location"

      raster.status = Mapscript::MS_ON
      #raster.setProjection( "+init=" + str(epsg).lower() )
      raster.dump = Mapscript::MS_TRUE

      #raster.setProjection('init=epsg:4326')
      raster.metadata.set('wcs_formats', 'GEOTIFF')
      raster.metadata.set('wms_title', @layer.name)
      raster.metadata.set('wms_srs', 'EPSG:4326 EPSG:3857 EPSG:4269 EPSG:900913')
      raster.debug = Mapscript::MS_TRUE

      Mapscript::msIO_installStdoutToBuffer
      result = map.OWSDispatch(ows)
      content_type = Mapscript::msIO_stripStdoutBufferContentType || "text/plain"
      result_data = Mapscript::msIO_getStdoutBufferBytes

      send_data result_data, :type => content_type, :disposition => "inline"
      Mapscript::msIO_resetHandlers
    rescue RuntimeError => e
      @e = e
      render :layout =>'application'
    end
  end


  #TODO merge wms and wm2 into one...or use tilecache for serving layers
  #this action lists all visible layers that have maps in them, and thus should
  #have a tileindex and something to view.
  def wms2

    @layer_name = params[:LAYERS]
    begin
      ows = Mapscript::OWSRequest.new

      ok_params = Hash.new
      # params.each {|k,v| k.upcase! } frozen string error

      params.each {|k,v| ok_params[k.upcase] = v }

      [:request, :version, :transparency, :service, :srs, :width, :height, :bbox, :format, :srs, :layers].each do |key|

        ows.setParameter(key.to_s, ok_params[key.to_s.upcase]) unless ok_params[key.to_s.upcase].nil?
      end

      ows.setParameter("STYLES", "")
      #ows.setParameter("LAYERS", "image")

      map = Mapscript::MapObj.new(File.join(RAILS_ROOT, '/db/maptemplates/wms.map'))
      projfile = File.join(RAILS_ROOT, '/lib/proj')
      map.setConfigOption("PROJ_LIB", projfile)
      #map.setProjection("init=epsg:900913")
      map.applyConfigOptions

      # logger.info map.getProjection
      map.setMetaData("wms_onlineresource",
        "http://" + request.host_with_port  + "/layers/wms2")
      unless @layer_name

        Layer.visible.each do |layer|
          if layer.rectified_maps_count > 0
            raster = Mapscript::LayerObj.new(map)
            #raster.name = "layer_"+layer.id.to_s
            raster.name = "layer_"+layer.id.to_s
            raster.type =  Mapscript::MS_LAYER_RASTER
            raster.tileindex = layer.tileindex_path
            raster.tileitem = "Location"

            raster.status = Mapscript::MS_ON
            raster.dump = Mapscript::MS_TRUE

            raster.metadata.set('wcs_formats', 'GEOTIFF')
            # raster.metadata.set('wms_title', "layer "+layer.id.to_s)
            raster.metadata.set('wms_title', layer.id.to_s + ": "+snippet(layer.name, 15))

            raster.metadata.set('wms_abstract', layer.rectified_maps_count.to_s + "maps. "+
                layer.rectified_percent.to_i.to_s + "% Complete"+
                "[Depicts:"+layer.depicts_year.to_s+"]")

            raster.metadata.set('wms_keywordlist', 'depictsYear:'+layer.depicts_year.to_s +
                ',totalMaps:' + layer.maps.count.to_s +
                ',numberWarpedMaps:'+ layer.rectified_maps_count.to_s +
                ',percentComplete:'+ layer.rectified_percent.to_i.to_s +
                ',lastUpdated:' + layer.updated_at.to_s )
            raster.metadata.set('wms_srs', 'EPSG:4326 EPSG:4269 EPSG:900913')
            raster.debug = Mapscript::MS_TRUE
          end
        end

      else
        single_layer = Layer.find(@layer_name.to_s.delete("layer_"))
        raster = Mapscript::LayerObj.new(map)
        raster.name = "layer_"+single_layer.id.to_s
        raster.type =  Mapscript::MS_LAYER_RASTER
        raster.tileindex = single_layer.tileindex_path
        raster.tileitem = "Location"

        raster.status = Mapscript::MS_ON
        raster.dump = Mapscript::MS_TRUE

        raster.metadata.set('wcs_formats', 'GEOTIFF')
        raster.metadata.set('wms_title', single_layer.name)
        raster.metadata.set('wms_srs', 'EPSG:4326 EPSG:4269 EPSG:900913')
        raster.metadata.set('wms_keywordlist', 'depictsYear:'+layer.depicts_year.to_s +
            ',totalMaps:' + layer.maps.count.to_s +
            ',warpedMaps:'+ layer.rectified_maps_count.to_s +
            ',percentComplete:'+ layer.rectified_percent.to_i.to_s +
            ',lastUpdated:' + layer.updated_at.to_s )

        raster.debug = Mapscript::MS_TRUE
      end

      Mapscript::msIO_installStdoutToBuffer
      result = map.OWSDispatch(ows)
      content_type = Mapscript::msIO_stripStdoutBufferContentType || "text/plain"
      result_data = Mapscript::msIO_getStdoutBufferBytes

      send_data result_data, :type => content_type, :disposition => "inline"
      Mapscript::msIO_resetHandlers
    rescue RuntimeError => e
      @e = e
      render :action => 'wms',:layout =>'application'
    end
  end

  def tile
    x = params[:x].to_i
    y = params[:y].to_i
    z = params[:z].to_i
    #for Google/OSM tile scheme we need to alter the y:
    y = ((2**z)-y-1)
    #calculate the bbox
    params[:bbox] = get_tile_bbox(x,y,z)
    #build up the other params
    params[:status] = "warped"
    params[:format] = "image/png"
    params[:service] = "WMS"
    params[:version] = "1.1.1"
    params[:request] = "GetMap"
    params[:srs] = "EPSG:900913"
    params[:width] = "256"
    params[:height] = "256"
    #call the wms thing
    wms

  end

  private

  def check_if_layer_is_editable
    if user_signed_in? and  current_user.has_role?("administrator")
      @layer = Layer.find(params[:id])
    else
      flash[:notice] = "Sorry, you cannot edit another person's Layer"
      redirect_to layer_path
    end
  end


  #
  # tile utility methods. calculates the bounding box for a given TMS tile.
  # Based on http://www.maptiler.org/google-maps-coordinates-tile-bounds-projection/
  # GDAL2Tiles, Google Summer of Code 2007 & 2008
  # by  Klokan Petr Pridal
  #
  def get_tile_bbox(x,y,z)
    min_x, min_y = get_merc_coords(x * 256, y * 256, z)
    max_x, max_y = get_merc_coords( (x + 1) * 256, (y + 1) * 256, z )
    return "#{min_x},#{min_y},#{max_x},#{max_y}"
  end

  def get_merc_coords(x,y,z)
    resolution = (2 * Math::PI * 6378137 / 256) / (2 ** z)
    merc_x = (x * resolution -2 * Math::PI  * 6378137 / 2.0)
    merc_y = (y * resolution - 2 * Math::PI  * 6378137 / 2.0)
    return merc_x, merc_y
  end

  #little helper method
  def snippet(thought, wordcount)
    thought.split[0..(wordcount-1)].join(" ") +(thought.split.size > wordcount ? "..." : "")
  end

  def find_layer
    @layer = Layer.find(params[:id])
  end

  def choose_layout_if_ajax
    if request.xhr?
      @xhr_flag = "xhr"
      render :layout => "layer_tab_container"
    end
  end

  def bad_record
    #logger.error("not found #{params[:id]}")
    respond_to do | format |
      format.html do
        flash[:notice] = "Layer not found"
        redirect_to :action => :index
      end
      format.json {render :json => {:stat => "not found", :items =>[]}.to_json, :status => 404}
    end
  end

  def store_location
    case request.parameters[:action]
    when "metadata"
      anchor = "Metadata_tab"
    when "export"
      anchor = "Export_tab"
    else
      anchor = ""
    end
    if request.parameters[:action] &&  request.parameters[:id]
      session[:return_to] = layer_path(:id => request.parameters[:id], :anchor => anchor)
    else
      session[:return_to] = request.request_uri
    end
  end

  def layer_params
    params.require(:layer).permit(:name, :description, :source_uri, :depicts_year)
  end

end
