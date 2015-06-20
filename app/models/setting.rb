class Setting < ActiveRecord::Base
  SITE_STATUSES = ["online", "read_only"]
  
  validate :check_status
  after_initialize :default_values
  
  def check_status
    unless Setting::SITE_STATUSES.include? self.site_status
      errors.add :base, 'Site status can only be one of '+ Setting::SITE_STATUSES.to_s
    end
  end
  
  def default_values
    self.site_status ||= "online"
    self.banner_text ||= APP_CONFIG["read_only_text"]
  end
end