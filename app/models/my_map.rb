class MyMap < ActiveRecord::Base
belongs_to :user
belongs_to :map, :foreign_key => "map_id"
validates_uniqueness_of :user_id, :scope =>  :map_id, :message => "Map has already been saved."

end
