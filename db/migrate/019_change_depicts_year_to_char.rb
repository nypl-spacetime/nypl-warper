class ChangeDepictsYearToChar < ActiveRecord::Migration
  def self.up
    remove_column :layers, :depicts_year
    add_column :layers, :depicts_year, :string, :limit => 4, :default => ""
    # note, these lines are PostgreSQL specific
    # first, look in the layer title to regexp match the last year mentioned
    execute "update layers set depicts_year =
        substring(name from '.*(1[3456789][0-9][0-9])')
        where depicts_year='' or depicts_year is null"
    # then, look in the layer properties to regexp match the last year
    # mentioned
    execute "update layers set depicts_year = 
        (select substring(value from '.*(1[3456789][0-9][0-9])') from
            layer_properties where layer_id=layers.id and name like 'date_%'
            limit 1)
        where depicts_year = '' or depicts_year is null"
  end

  def self.down
    remove_column :layers, :depicts_year
    add_column :layers, :depicts_year, :timestamp
  end
end
