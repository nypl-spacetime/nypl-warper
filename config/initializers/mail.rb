# Email settings
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "outbounds9.obsmtp.com",
  :port => 25,
  :domain => "maps.nypl.org"

}
