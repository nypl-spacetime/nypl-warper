class ImportsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :check_administrator_role

  before_filter :find_import, :except => [:index, :new, :create]
  before_filter :check_imported, :only => [:start]
  
  rescue_from ActiveRecord::RecordNotFound, :with => :bad_record

  def index
    @imports = Import.order("updated_at DESC").paginate(:page => params[:page],:per_page => 30)
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
    @logtext = @import.status == :ready ? "" : File.open("log/#{@import.log_filename}").read 
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
