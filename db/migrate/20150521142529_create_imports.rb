class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.integer :user_id
      t.integer :status
      t.integer :import_type
      t.string   :uuid
      t.string   :since_date
      t.string   :until_date
      t.timestamps null: false
      t.datetime :finished_at
    end
  end
end
