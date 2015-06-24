class FlagsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_administrator_role, :except => [:create]

  #before_filter :find_flag, :except => [:index, :new, :create]

  
  rescue_from ActiveRecord::RecordNotFound, :with => :bad_record
  
  #show, :index, :create, :close
  
  def index
    @flags = Flag.all
  end
  
  def create
    @parent = flagged_item
    @flag = flagged_item.flags.build(flag_params)
    @flag.reporter = current_user
    
    if @flag.save
      redirect_to flagged_url(@parent), notice: "Flag saved."
    else
      redirect_to flagged_url(@parent), error: "Error saving flag."
    end

  end
  
  def close
    
  end
  
  
  private
  
  def bad_record
    respond_to do | format |
      format.html do
        flash[:notice] = "Flag not found"
        redirect_to :root
      end
      format.json {render :json => {:stat => "not found", :items =>[]}.to_json, :status => 404}
    end
  end
  
  def flag_params
    params.require(:flag).permit(:id, :flaggable_id, :flaggable_type, :message, :reason)
  end
  
  def flagged_item
    case
    when params[:map_id] then Map.find_by_id(params[:map_id])
    when params[:user_id] then User.find_by_id(params[:user_id])
    end    
  end  

  def flagged_url(flagged_item)
    case
    when params[:map_id] then map_url(flagged_item)
    when params[:user_id] then user_url(flagged_item)
    end    
  end
  
end