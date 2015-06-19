class UsersController < ApplicationController
  layout 'application'
  
  before_filter :authenticate_user!, :only => [:show, :edit, :update]

  before_filter :check_super_user_role, :only => [:index, :destroy, :enable, :disable, :stats, :disable_and_reset, :force_confirm]

  rescue_from ActiveRecord::RecordNotFound, :with => :bad_record
  
  helper :sort
  include SortHelper

  def stats
    sort_init "total_count"
    sort_update
    
    @html_title = "Users Stats"

    @period = params[:period]
    period_where_clause = ""

    if @period == "hour"
      period_where_clause = "where created_at > '#{1.hour.ago.to_s(:db)}'"
    elsif @period == "day"
      period_where_clause = "where created_at > '#{1.day.ago.to_s(:db)}'"
    elsif @period == "week"
      period_where_clause = "where created_at > '#{1.week.ago.to_s(:db)}'"
    elsif @period == "month"
      period_where_clause = "where created_at > '#{1.month.ago.to_s(:db)}'"
    else
      @period = "total"
      period_where_clause = "" 
    end
    
    the_sql = "select whodunnit, COUNT(whodunnit) as total_count,
      COUNT(case when item_type='Gcp' then 1 end) as gcp_count,
      COUNT(case when item_type='Map' or item_type='Mapscan' then 1 end) as map_count,
      COUNT(case when event='update' and item_type='Gcp' then 1 end) as gcp_update_count,
      COUNT(case when event='create' and item_type='Gcp' then 1 end) as gcp_create_count,
      COUNT(case when event='destroy' and item_type='Gcp' then 1 end) as gcp_destroy_count 
      from versions #{period_where_clause} group by whodunnit ORDER BY #{sort_clause}"
    
    @users_activity  = PaperTrail::Version.paginate_by_sql(the_sql,:page => params[:page], :per_page => 30)
 
  end


  def index
    @html_title = "Users"
    sort_init 'email'
    sort_update
    @query = params[:query]
    @field = %w(login email provider).detect{|f| f == (params[:field])}
    if @query && @query.strip.length > 0 && @field
      conditions = ["#{@field}  ~* ?", '(:punct:|^|)'+@query+'([^A-z]|$)']
    else
      conditions = nil
    end
    @users = User.where(conditions).order(sort_clause).paginate(:page=> params[:page], :per_page => 30)

  end

  def index_for_group
    @group = Group.find(params[:group_id])
    @html_title = "Users in Group " + @group.id.to_s
    sort_init 'email'
    sort_update
    @query = params[:query]
    @field = %w(login email provider).detect{|f| f == (params[:field])}
    if @query && @query.strip.length > 0 && @field
      conditions = ["#{@field}  ~* ?", '(:punct:|^|)'+@query+'([^A-z]|$)']
    else
      conditions = nil
    end
    @users = @group.users.where(conditions).order(sort_clause).paginate(:page=> params[:page],
:per_page => 30)
    render :action => 'index'
  end

  def show
    @user = User.find(params[:id]) || current_user
    @html_title = "Showing User "+ @user.login.capitalize
    @mymaps = @user.maps.order("updated_at DESC").paginate(:page => params[:page],:per_page => 8)
    @current_user_maps = current_user.maps
    respond_to do | format |
      format.html {}
      format.js {}
      format.json {render :json => {:stat => "ok",:items => @user.to_a}.to_json(:only =>[:login, :created_at, :stat, :items, :enabled ])  }
    end

  end



  def edit
    @html_title = "Edit User Setttings"
    @user = current_user
  end

  def update
    @user = User.find(current_user)
    if @user.update_attributes(params[:user])
      flash[:notice] = "User updated"
      redirect_to :action => 'show', :id => current_user
    else
      render :action => 'edit'
    end
  end

  def destroy
    @user = User.find(params[:id])
    unless @user.has_role?("administrator") ||  @user.has_role?("super user")
      if @user.destroy
        flash[:notice] = "User successfully deleted"
      else
        flash[:error] = "User could not be deleted"
      end
    else
      flash[:error] = "Admins cannot be destroyed"
    end
    redirect_to :action => 'index'
  end

  def disable_and_reset
    @user = User.find(params[:id])
    if @user.provider?
      flash[:error] = "Sorry, users from other providers are not able to be reset"
      return redirect_to :action => 'show'
    end
    unless @user.has_role?("administrator") ||  @user.has_role?("super user")
      generated_password = Devise.friendly_token.first(8)
      @user.password=generated_password
      @user.password_confirmation=generated_password
      
      if @user.save
        UserMailer.disabled_change_password(@user).deliver_now
        @user.send_reset_password_instructions
        flash[:notice] = "User changed and an email sent with password reset link"
      else
        flash[:error] = "Sorry, there was a problem changingin this user"
      end
      
    else
      flash[:error] = "Admins cannot be disabled and reset, sorry"
    end
    
    redirect_to :action => 'show'
  end

  def disable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "User disabled"
    else
      flash[:error] = "There was a problem disabling this user."
    end
    redirect_to :action => 'index'
  end

  def enable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = "User enabled"
    else
      flash[:error] = "There was a problem enabling this user."
    end
    redirect_to :action => 'index'
  end
  
  def force_confirm
    @user = User.find(params[:id])
    if !@user.confirmed?
      @user.force_confirm!
      if @user.confirmed? 
        flash[:notice] = "User confirmed"
      else
        flash[:error] = "There was a problem confirming this user."
      end
    else
      flash[:notice] = "User already confirmed"
    end
    redirect_to :action => 'index'
  end
  
  

  def bad_record
    respond_to do | format |
      format.html do
        flash[:notice] = "User not found"
        redirect_to root_path
      end
      format.json {render :json => {:stat => "not found", :items =>[]}.to_json, :status => 404}
    end
  end


end
