class AddStatusField < ActiveRecord::Migration
    def self.up
        add_column :mapscans, :status, :integer
    end

    def self.down
        remove_column :mapscans, :status
    end
end
