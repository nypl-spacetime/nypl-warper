class AddOriginYearToMap < ActiveRecord::Migration
  def change
    add_column :maps, :origin_year, :integer
  end
end
