class AddImageAttachmentToMapscan < ActiveRecord::Migration
  def self.up
  	add_column :mapscans,  :content_type, :string
     #already has filename
       add_column :mapscans,  :thumbnail, :string
       add_column :mapscans,  :size, :integer
       
       add_column :mapscans,  :width, :integer
       add_column :mapscans,  :height, :integer
  end

  def self.down
  	remove_column :mapscans,  :content_type
   
      remove_column :mapscans,  :thumbnail
     remove_column :mapscans,  :size
        remove_column :mapscans,  :width
       remove_column :mapscans,  :height
  end
end

  
