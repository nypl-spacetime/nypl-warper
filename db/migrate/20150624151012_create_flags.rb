class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.integer    :flaggable_id
      t.string     :flaggable_type
      t.string     :reason
      t.text       :message
      t.integer    :reporter_id
      t.integer    :closer_id
      t.timestamp  :closed_at
      t.timestamps  null: false
    end
    
    add_index :flags, :flaggable_id
  end
end
