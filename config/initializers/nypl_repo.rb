#Loads in the authentication token per rails env

if File.exist?(File.join(RAILS_ROOT, "/config/nypl_repo.yml"))
  config_file = YAML.load_file("#{RAILS_ROOT}/config/nypl_repo.yml")
  REPO_CONFIG = config_file[ENV['RAILS_ENV']].symbolize_keys
else
  REPO_CONFIG = {}
end
