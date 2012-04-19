# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.

#if we want auditing in dev mode, we gotta set these to true see above# it sucks for dev. 
config.cache_classes = false
#config.action_controller.perform_caching             = true

#config.cache_classes = false
#config.action_controller.perform_caching             = false


# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
#config.action_view.cache_template_extensions         = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

GDAL_PATH  = ""
GOOGLE_ANALYTICS_CODE = "UA-12240034-2" 
GOOGLE_ANALYTICS_COOKIE_PATH = "/warper-dev/"
ActionController::Base.relative_url_root = "/warper-dev" 
Yahoo_app_id = "lbQ2VNLV34EoEmxF9dguamWEFSXjI7adJ.ACHkdChT2JGmQ0Bj.jP1cF0nmh5XP3"
