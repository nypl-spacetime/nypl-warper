class Flag < ActiveRecord::Base
  belongs_to :flaggable, polymorphic: true
  belongs_to :reporter, :class_name => "User"
  belongs_to :closer, :class_name => "User"
 
  validates_presence_of :flaggable_id
  validates_presence_of :flaggable_type
  validates_inclusion_of :reason, :in => %w( abuse copyright error wrong_warp bad_points not_loading other ), :message => "reason type is not allowed", :allow_nil => true
  
  def close(user)
    self.closer = user
    self.closed_at = Time.now
    save
  end
  
end
