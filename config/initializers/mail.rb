# Email settings
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "bm2.nypl.net",
  :port => 25,
  :domain => "maps.nypl.org"

}
