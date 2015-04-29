class HomeController < ApplicationController

  layout 'application'
  def index
    @html_title =  "Home"
    @html_title = @html_title 

    @maps = Map.find(:all, 
                             :order => "maps.updated_at DESC",
                             :conditions => 'status = 4', 
                             :limit => 3, 
                            :include => :gcps)


    if logged_in?
      @my_maps = current_user.maps.find(:all, :order => "updated_at DESC", :limit => 3)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @maps }
    end
  end





end
