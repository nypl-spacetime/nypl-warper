class  OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def failure
    set_flash_message :alert, :failure, kind: OmniAuth::Utils.camelize(failed_strategy.name), reason: failure_message
    redirect_to after_omniauth_failure_path_for(resource_name)
  end

  def twitter
    @user = User.find_for_twitter_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Twitter"
      sign_in_and_redirect @user, :event => :authentication
     # sign_in @user, :event => :authentication
     # redirect_to session[:user_return_to] root_path
    else
      session["devise.twitter_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end
  
   def osm
    @user = User.find_for_osm_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Osm"
      sign_in_and_redirect @user, :event => :authentication
     # sign_in @user, :event => :authentication
     # redirect_to session[:user_return_to] root_path
    else
      session["devise.osm_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end
  
  def mediawiki
    @user = User.find_for_mediawiki_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Mediawiki"
      sign_in_and_redirect @user, :event => :authentication
     # sign_in @user, :event => :authentication
     # redirect_to session[:user_return_to] root_path
    else
      session["devise.mediwiki_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end
  
  def github
    @user = User.find_for_github_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Github"
      sign_in_and_redirect @user, :event => :authentication
     # sign_in @user, :event => :authentication
     # redirect_to session[:user_return_to] root_path
    else
      session["devise.github_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end
  
  def google_oauth2
    @user = User.find_for_google_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
      sign_in_and_redirect @user, :event => :authentication
      # sign_in @user, :event => :authentication
      # redirect_to session[:user_return_to] root_path
    else
      session["devise.google_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end
  
  def facebook
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook"
      sign_in_and_redirect @user, :event => :authentication
      # sign_in @user, :event => :authentication
      # redirect_to session[:user_return_to] root_path
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to root_path
    end
  end
  
  protected

  def failed_strategy
    request.respond_to?(:get_header) ? request.get_header("omniauth.error.strategy") : request.env["omniauth.error.strategy"]
  end

  def failure_message
    exception = request.respond_to?(:get_header) ? request.get_header("omniauth.error") : request.env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= (request.respond_to?(:get_header) ? request.get_header("omniauth.error.type") : request.env["omniauth.error.type"]).to_s
    error.to_s.humanize if error
  end

  def after_omniauth_failure_path_for(scope)
    new_session_path(scope)
  end

  def translation_scope
    'devise.omniauth_callbacks'
  end
  

end
