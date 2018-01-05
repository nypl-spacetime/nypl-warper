CONFIG_PATH="#{Rails.root}/config/application.yml"

APP_CONFIG = YAML.load_file(CONFIG_PATH)[Rails.env]

#directories for maps and layer/mosaic tileindex shapefiles
DST_MAPS_DIR = APP_CONFIG['dst_maps_dir'].blank? ? File.join(Rails.root, '/public/mapimages/dst/') : APP_CONFIG['dst_maps_dir']
SRC_MAPS_DIR = APP_CONFIG['src_maps_dir'].blank? ? File.join(Rails.root, '/public/mapimages/src/') : APP_CONFIG['src_maps_dir']
MASK_DIR = APP_CONFIG['mask_dir'].blank? ? File.join(Rails.root, '/public/mapimages/') : APP_CONFIG['mask_dir']
TILEINDEX_DIR = APP_CONFIG['tileindex_dir'].blank? ? File.join(Rails.root, '/db/maptileindex') : APP_CONFIG['tileindex_dir']

#if gdal is not on the normal path
GDAL_PATH = APP_CONFIG['gdal_path'] || ""

#
# Uncomment and populate the config file if you want to enable:
# MAX_DIMENSION = will reduce the dimensions of the image when uploaded
# MAX_ATTACHMENT_SIZE = will reject files that are bigger than this
# GDAL_MEMORY_LIMIT = limit the amount of memory available to gdal 
#
#MAX_DIMENSION = APP_CONFIG['max_dimension']
#MAX_ATTACHMENT_SIZE = APP_CONFIG['max_attachment_size']
#GDAL_MEMORY_LIMIT = APP_CONFIG['gdal_memory_limit']

# See the value of AWS Parameter store (/production/ses/mapsATnypl.org/credentials)
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "email-smtp.us-east-1.amazonaws.com",
  :port => 25,
  :domain => "maps.nypl.org",
  :user_name => ENV['MAPS_SMPT_USERNAME'],
  :password => ENV['MAPS_SMPT_PASSWORD'],
  :authentication => :login,
  :enable_starttls_auto => true
  }
#ActionMailer::Base.delivery_method = :sendmail

ActionMailer::Base.default_url_options[:host] = APP_CONFIG['host']

Devise.mailer_sender = APP_CONFIG['email']
