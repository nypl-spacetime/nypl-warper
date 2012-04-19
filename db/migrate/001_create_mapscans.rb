class CreateMapscans < ActiveRecord::Migration
  def self.up
    create_table :mapscans do |t|
      t.string :title
      t.text :description
      t.string :filename
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps
    end
  end

  def self.down
    drop_table :mapscans
  end
end
