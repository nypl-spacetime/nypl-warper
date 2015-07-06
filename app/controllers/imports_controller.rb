class ImportsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :check_administrator_role

  before_filter :find_import, :except => [:index, :new, :create]
  before_filter :check_imported, :only => [:start]
  
  rescue_from ActiveRecord::RecordNotFound, :with => :bad_record

  helper :sort
  include SortHelper
  
  def index
    sort_init('created_at', {:default_order => "desc"})
    sort_update
    if params[:sort_order] && params[:sort_order] == "desc"
      sort_nulls = " NULLS LAST"
    else
      sort_nulls = " NULLS FIRST"
    end
    order_options = sort_clause + sort_nulls
    
    @imports = Import.order(order_options).paginate(:page => params[:page],:per_page => 50)
  end

  def new
    @import = Import.new
  end

  def create
    @import = Import.new(import_params)
    @import.user = current_user
    if @import.save
      flash[:notice] = "New Import Created!"
      redirect_to import_url(@import)
    else
      flash[:error] = "Something went wrong creating the import"
      render :new
    end
  end


  def edit
  end

  def show
    
    if !@import.log_filename.blank? && File.exists?("log/#{@import.log_filename}")
      @logtext = File.open("log/#{@import.log_filename}").read 
    elsif !File.exists?("log/#{@import.log_filename}")
      @logtext = "log file not found"
    else
      @logtext = ""
    end
     @count = nil
    if @import.status == :ready && @import.import_type == :latest
      @count = @import.count_latest()
    end
  end

  def destroy
    if  @import.destroy
      flash[:notice] = "Import deleted!"
    else
      flash[:notice] = "Import couldn't be deleted."
    end
    redirect_to imports_path
  end
 
  def update
    if @import.update_attributes(import_params)
      flash[:notice] = "Successfully updated import."
      redirect_to import_url(@import)
    else
      flash[:error] = "Something went wrong updating the import"
      render :action => 'edit'
    end
  end

  def start
    
    if @import.import_type == :latest
      @import.prepare_run
      Spawnling.new do
        @import.import!(true)
      end
    else
      @import.import!
    end
    
    redirect_to @import
  end

  def status
    render :text => @import.status
  end

  private
  
  def find_import
    @import = Import.find(params[:id])
  end

  def check_imported
    if @import.status != :ready
      flash[:notice] = "Sorry, this import is either running or finished."
      redirect_to imports_path
    end
  end

  def bad_record
    respond_to do | format |
      format.html do
        flash[:notice] = "Import not found"
        redirect_to :root
      end
      format.json {render :json => {:stat => "not found", :items =>[]}.to_json, :status => 404}
    end
  end
  
  def import_params
    params.require(:import).permit(:uuid, :import_type, :since_date, :until_date)
  end

end
