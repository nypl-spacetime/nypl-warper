class HomeController < ApplicationController

  layout 'application'
  skip_before_filter :check_site_online, :only => [:offline]
  skip_before_filter :check_site_read_only
  
  def index
    @html_title =  "Home - "
    
    @maps = Map.where(:status => 4).order(:updated_at =>  :desc).limit(3).includes(:gcps)
    
    @layers = Layer.all.order(:updated_at => :desc).limit(3).includes(:maps)
    
    @year_min = Map.minimum(:issue_year)
    @year_max = Map.maximum(:issue_year)
    @year_min = 1600 if @year_min == 0
    @year_max = 2015 if @year_max == 0
    
    if user_signed_in?
      @my_maps = current_user.maps.order(:updated_at => :desc).limit(3)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @maps }
    end
  end


end
