class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?

  before_filter :check_site_online
  before_filter :check_site_read_only, :unless => :devise_controller?
  
  before_filter :check_rack_attack
  
  def info_for_paper_trail
    { :ip => request.remote_ip, :user_agent => request.user_agent }
  end
    
  def check_super_user_role
    check_role('super user')
  end

  def check_administrator_role
    check_role("administrator")
  end

  def check_developer_role
    check_role("developer")
  end


  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit :login, :description, :email, :password, :password_confirmation
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit :login, :description, :email, :password, :password_confirmation, :current_password
    end
  end

  def check_role(role)
    unless user_signed_in? && @current_user.has_role?(role)
      permission_denied
    end
  end

  def permission_denied
    flash[:error] = "Sorry you do not have permission to view that."
    redirect_to root_path
  end
  
  
  def check_site_read_only
    if APP_CONFIG['status'] == :read_only || (Setting.last && Setting.last.site_status == "read_only")
      unless user_signed_in? && @current_user.has_role?("administrator")
        if request.xhr?
          response.headers["Error"] =  "Site readonly"
          render :text => "Site readonly", :status => :service_unavailable, :content_type => "text/plain"
        else
          redirect_to root_path
        end
        
      end
    end
  end
  
  def check_site_online
    
    if APP_CONFIG['status'] == :offline
      if request.xhr?
        response.headers["Error"] =  "Site offline for maintenance"
        render :text => "Site offline for maintenance", :status => :service_unavailable, :content_type => "text/plain"
      elsif params[:action] == "wms" || params[:action] == "tile"
        send_file("#{Rails.root}/app/assets/images/offline-map-tile.png", :type => "image/png", :disposition => 'inline', :x_sendfile => true )
      else
        redirect_to :controller => "/home", :action => "offline"
      end
    end
    
  end

  def check_rack_attack
    if request.env['rack.attack.flag_user'] == true

      flag =  Flag.find_or_initialize_by(:flaggable_id => current_user.id) 

      if flag.new_record?
        flag.flaggable_type = "User"
        flag.reason = "request_throttle"
        flag.message =  [
          env['rack.attack.matched'],
          env['rack.attack.match_type'],
          env['rack.attack.match_data']
        ].inspect
        flag.save
      end

    end
  end


end


