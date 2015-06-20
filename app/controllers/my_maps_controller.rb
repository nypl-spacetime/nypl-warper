class MyMapsController < ApplicationController
  before_filter :get_user
  before_filter :authenticate_user!, :only => [:list, :show, :create, :destroy]
  
  skip_before_filter :check_site_read_only,  :only => [:list]

  def list
    @mymaps = @user.maps.order("updated_at DESC").paginate(:page => params[:page],:per_page => 8)
    
    @remove_from = true
    @html_title = "#{@user.login.capitalize}'s 'My Maps' on "
  end


  def create

    if @user == current_user 
      @map = Map.find(params[:map_id])
      um = @user.my_maps.new(:map => @map)
      if um.save     
        flash[:notice] = "Map saved to My Maps"
      else
        flash[:notice] = um.errors.on(:user_id)
      end

    else
      flash[:notice] = "You cannot add a map to another user!"
      #TODO redirect back with message
    end

    redirect_to my_maps_path
    #TODO catch when http referer is down

  end

  #we shouldnt be able to remove a map we uploaded
  def destroy
    if @user == current_user 

      my_map = @user.my_maps.find_by_map_id(params[:map_id])

      if my_map.destroy 
        flash[:notice] = "Map removed from list!"
      else
        flash[:notice] = "Map coudn't be removed from list"
      end
    else
     flash[:notice] = "You cannot remove other people's maps!"

    end
    redirect_to my_maps_path
  end

  private
  def get_user
    if User.exists?(params[:user_id])
      @user = User.find(params[:user_id])
    else

      redirect_to users_path
    end

  end


end
