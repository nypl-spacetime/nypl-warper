class AddUniqueIndexToFlags < ActiveRecord::Migration
  def change
    add_index :flags, [:flaggable_id, :flaggable_type], unique: true
  end
end
