class AdminsController < ApplicationController
  layout 'application'
  
  before_filter :authenticate_user!

  before_filter :check_administrator_role
   
  def index
    @html_title = "Admin - "
    
  end
  
end
