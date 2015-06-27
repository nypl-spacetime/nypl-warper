class FlagsController < ApplicationController
  layout 'application'
    
  before_filter :authenticate_user!
  before_filter :check_administrator_role

  rescue_from ActiveRecord::RecordNotFound, :with => :bad_record 

  helper :sort
  include SortHelper
  
  def index
    sort_init('updated_at', {:default_order => "desc"})
    sort_update
    if params[:sort_order] && params[:sort_order] == "desc"
      sort_nulls = " NULLS LAST"
    else
      sort_nulls = " NULLS FIRST"
    end
    order_options = sort_clause + sort_nulls
    
    @per_page = params[:per_page] || 2
    paginate_params = {
      :page => params[:page],
      :per_page => @per_page
    }
    
    @flags =  Flag.order(order_options).paginate(paginate_params)
  end
  
  def create
    @parent = flagged_item
    @flag =   flagged_item.flags.build(flag_params)
    @flag.reporter = current_user
    
    if @flag.save
      redirect_to flagged_url(@parent), notice: "Flag saved."
    else
      redirect_to flagged_url(@parent), error: "Error saving flag."
    end

  end
   
  def close
    @flag = Flag.find_by_id(params[:id])
    if @flag.close(current_user)
      flash[:notice] = "Flag closed."
    else
      flash[:error] = "Error closing flag."
    end
     
    redirect_to :action => 'index'
  end
  
  def destroy
    @flag = Flag.find_by_id(params[:id])
    if @flag.destroy
      flash[:notice] = "Flag deleted."
    else
      flash[:error] = "Error deleting flag."
    end
     
    redirect_to :action => 'index'
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