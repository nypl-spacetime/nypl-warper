class AddBboxToLayer < ActiveRecord::Migration
  def self.up
    add_column :layers, :bbox, :string
    Layer.reset_column_information
    
    #now update bbox info
    Layer.all.each do |l|
      l.set_bounds
      l.save!
    end
  end

  def self.down
    remove_column :layers, :bbox
  end
end
