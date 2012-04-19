class MyMapsController < ApplicationController
before_filter :get_user
before_filter :login_required, :only => [:list, :show, :create, :destroy]

def list
  @html_title = "Listing My Maps"
  @mymaps = @user.maps.paginate(:page => params[:page],:per_page => 8, :order => "updated_at DESC")
 @remove_from = true
 if request.xhr?
  render :action => 'list.rjs'
 end
end

#def new  
#end

def show
@map = @user.my_maps.find(params[:id])
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

def destroy
  if @user == current_user 
    #note, mapscan_id is the database field name
    my_map = @user.my_maps.find_by_mapscan_id(params[:map_id])
    if my_map.destroy 
      flash[:notice] = "Map removed from list!"
    else
      flash[:notice] = "Map coudn't be deleted"
    end
  else
    flash[:notice]= "You cannot remove other people's maps!"

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
