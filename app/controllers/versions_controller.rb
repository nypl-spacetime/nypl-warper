class VersionsController < ApplicationController
  layout "application"
  
  before_filter :authenticate_user!, :only => [ :revert_map, :revert_gcp]
  
  skip_before_filter :check_site_read_only,  :only => [:show, :index, :for_user, :for_map, :for_map_model]

  def show
    @version  =  PaperTrail::Version.find(params[:id])
  end

  def index
    @html_title = "Recent Activity"
    @versions = PaperTrail::Version.order(:created_at => :desc).paginate(:page => params[:page],
      :per_page => 50)
    @title = "Recent Activity For Everything"
    @linktomap = true
    render :action => 'index'
  end


  def for_user
    user_id = params[:id].to_i
    @user = User.where(id: user_id).first
    if @user
      @html_title = "Activity for " + @user.login.capitalize
      @title = "Recent Activity for User " +@user.login.capitalize
    else
      @html_title = "Activity for not found user #{params[:id]}"
      @title = "Recent Activity for not found user #{params[:id]}"
    end    
    
    order_options = "created_at DESC"
   
    @versions = PaperTrail::Version.where(:whodunnit => user_id).order(order_options).paginate(:page => params[:page],
      :per_page => 50)
    
    render :action => 'index'
  end

  def for_map
    @selected_tab = 5
    @current_tab = "activity"
    @map = Map.find(params[:id])
    @html_title = "Activity for Map " + @map.id.to_s
    
    order_options = "created_at DESC"
   
    @versions =  PaperTrail::Version.where("item_type = 'Map' AND item_id = ?", @map.id).order(order_options).paginate(:page => params[:page], :per_page => 20)

    @title = "Recent Activity for Map "+params[:id].to_s
    respond_to do | format |
      if request.xhr?
        @xhr_flag = "xhr"
        format.html { render  :layout => 'tab_container' }
      else
        format.html {render :layout => 'application' }
      end
      format.rss {render :action=> 'index'}
    end
  end
  
  

  def for_map_model
    @html_title = "Activity for All Maps"
    order_options = "created_at DESC"
    
    @versions =  PaperTrail::Version.where(:item_type => 'Map').order(order_options).paginate(:page => params[:page], :per_page => 20)

    @title = "Recent Activity for All Maps"
    render :action => 'index'
  end
  
  def revert_map
    @version = PaperTrail::Version.find(params[:id])
    if @version.item_type != "Map"
      flash[:error] = "Sorry this is not a map"
      return redirect_to :activity_details
    else
      map = Map.find(@version.item_id)
      reified_map = @version.reify(:has_many => true)
      new_gcps = reified_map.gcps.to_a
      map.gcps = new_gcps
      flash[:notice] = "Map reverted!"
      return redirect_to :activity_details
    end
  end
  
  def revert_gcp
    @version = PaperTrail::Version.find(params[:id])
    if @version.item_type != "Gcp"
      flash[:error] = "Sorry this is not a GCP"
      return redirect_to :activity_details
    else
      if @version.event == "create"
        if Gcp.exists?(@version.item_id.to_i)
          gcp = Gcp.find(@version.item_id.to_i)
          gcp.destroy
          flash[:notice] = "GCP Reverted and Deleted!"
          return redirect_to :activity_details
        end
      else
        gcp = @version.reify
        gcp.save 
        flash[:notice] = "GCP Reverted!"
        return redirect_to :activity_details
      end
    end
    
  end

end
