class AdminsController < ApplicationController
  layout 'application'
  
  before_filter :authenticate_user!

  before_filter :check_administrator_role

  def index
    @html_title = "Admin - "
  end
  
  
  def read_only
    
    @site_setting = Setting.last
    if @site_setting.nil?
      @site_setting = Setting.new
    end
    
  end
  
 
  def change_site_status
    if params[:setting_id]
      @site_setting = Setting.find_by_id(params[:setting_id])
    else
      @site_setting = Setting.new
    end
    if @site_setting.update(:site_status => params[:site_status], :banner_text => params[:banner_text] )
      flash[:notice] = "Changed site settings!"
    else
      flash[:error] = "There was an error changing site settings!"
    end
    redirect_to :read_only
  end

  
end
