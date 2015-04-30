#Loads in the authentication token per rails env
require "#{ Rails.root }/lib/nypl/nypl_repo.rb"

if File.exist?(File.join(Rails.root, "/config/nypl_repo.yml"))
  config_file = YAML.load_file("#{ Rails.root }/config/nypl_repo.yml")
  REPO_CONFIG = config_file[ENV['RAILS_ENV']].symbolize_keys
else
  REPO_CONFIG = {}
end
