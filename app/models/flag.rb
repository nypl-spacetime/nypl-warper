class Flag < ActiveRecord::Base
  belongs_to :flaggable, polymorphic: true
  belongs_to :reporter, :class_name => "User"
  belongs_to :closer, :class_name => "User"
 
  validates_uniqueness_of :flaggable_id, :scope => :flaggable_type 
  validates_presence_of :flaggable_id
  validates_presence_of :flaggable_type
  validates_inclusion_of :reason, :in => %w(request_throttle abuse copyright error wrong_warp bad_points not_loading other ), :message => "reason type is not allowed", :allow_nil => true
  
  after_create :send_email_report
  
  def close(user)
    self.closer = user
    self.closed_at = Time.now
    save
  end
  

  def send_email_report
    if APP_CONFIG["enable_throttling"] == true
      if flaggable_type == "User"
        begin
          UserMailer.flag_report(self).deliver_now
        rescue Exception => e
          logger.error "error with flag email " + e.inspect
        end
      end
    end
  end
  
end
