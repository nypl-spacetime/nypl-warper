class AddNyplMetadataFields < ActiveRecord::Migration
    def self.up
        add_column :mapscans, :nypl_digital_id, :string
        add_column :mapscans, :catnyp, :string
        add_column :mapscans, :uuid, :string
        add_column :mapscans, :parent_uuid, :string
    end

    def self.down
        remove_column :mapscans, :nypl_digital_id
        remove_column :mapscans, :catnyp
        remove_column :mapscans, :uuid
        remove_column :mapscans, :parent_uuid
    end
end
