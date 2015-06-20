class AdminsController < ApplicationController
  layout 'application'
  
  before_filter :authenticate_user!

  before_filter :check_administrator_role
  
  skip_before_filter :check_site_read_only,  :only => [:index]
   
  def index
    @html_title = "Admin - "
    
  end
  
end
