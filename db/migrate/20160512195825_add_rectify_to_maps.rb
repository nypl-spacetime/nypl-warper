class AddRectifyToMaps < ActiveRecord::Migration
  def change
    add_column :maps, :transform_options, :string, :default => "auto"
    add_column :maps, :resample_options, :string, :default => "cubic"
  end
end
