set :application, "warper"
set :repository,  "http://svn2.geothings.net/warper/"

#wrp.geothings.net
# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "wrp.geothings.net"
role :web, "wrp.geothings.net"
role :db,  "wrp.geothings.net", :primary => true

set :deploy_to, "/home/timwarp/wrp.geothings.net/"
set :use_sudo, false
set :checkout, "export"
set :user, "timwarp"

#tasks

desc "Tasks to execute after code update" 
   task :after_update_code, :roles => [:app, :db, :web] do
    # fix permissions
    run "chmod +x #{release_path}/script/process/reaper" 
    run "chmod +x #{release_path}/script/process/spawner" 
    run "chmod 755 #{release_path}/public/dispatch.*" 
    run "chmod 755 #{latest_release}/script/spin"
   end
   
   task :after_update_code, :roles => :app do
   
   db_config = "#{shared_path}/config/database.yml.production"
	 run "cp #{db_config} #{release_path}/config/database.yml"
   
  %w{mapimages}.each do |share|
    run "rm -rf #{release_path}/public/#{share}"
    run "mkdir -p #{shared_path}/system/#{share}"
    run "ln -nfs #{shared_path}/system/#{share} #{release_path}/public/#{share}"
 
   
  end

  
end
   
   desc "Link in the production extras" 
task :after_symlink do
	 run "mkdir -p #{shared_path}/system/mapfiles"

	#prob not needed...
    run "cp #{release_path}/db/mapfiles/test.map #{shared_path}/system/mapfiles/test.map"
    
     run "cp #{release_path}/db/mapfiles/default.map #{shared_path}/system/mapfiles/default.map"
    	run "rm -rf #{release_path}/db/mapfiles"
     run "ln -nfs #{shared_path}/system/mapfiles #{release_path}/db/mapfiles"
     
     #put the mapserv in this folder
      run "rm -rf #{release_path}/public/cgi"
    run "mkdir -p #{shared_path}/system/cgi"
    run "ln -nfs #{shared_path}/system/cgi #{release_path}/public/cgi"
 
end
   
   
   desc "Restarting after deployment" 
   task :after_deploy, :roles => [:app, :db, :web] do
    run "touch /home/timwarp/wrp.geothings.net/current/public/dispatch.fcgi" 
   end
   
   desc "Restarting after rollback" 
   task :after_rollback, :roles => [:app, :db, :web] do
    run "touch /home/timwarp/wrp.geothings.net/current/public/dispatch.fcgi" 
    end
    

