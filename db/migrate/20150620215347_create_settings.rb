class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :site_status
      t.text :banner_text
    end
  end
end
