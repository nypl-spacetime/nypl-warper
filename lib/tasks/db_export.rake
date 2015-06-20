namespace :warper do

  def dump_database
    database = Rails.configuration.database_configuration[Rails.env]["database"]
    dump_name = "#{database}-#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.dump"
    system "pg_dump -Fc -i > db/#{dump_name}"
      
    dump_name
  end
  
  
  desc "PostgreSQL database dump to db directory"
  task :dump_db => :environment do
    puts "[#{Time.now}] warper:dump started. dumping to db directory"
      
    dump_name = dump_database
      
    puts "[#{Time.now}] warper:dump finished. db/#{dump_name} created"
  end
  
  desc "Dump and backup to S3 Bucket"
  task :s3_backup_db => :environment do
    puts "[#{Time.now}] warper:s3_backup_db started. "
    
    secret = ENV['s3_db_secret_access_key'] || APP_CONFIG['s3_db_secret_access_key'] 
    key_id = ENV['s3_db_access_key_id'] || APP_CONFIG['s3_db_access_key_id'] 
    bucket_name = ENV['s3_db_bucket_name'] || APP_CONFIG['s3_db_bucket_name']
    bucket_path = ENV['s3_db_bucket_path'] || APP_CONFIG['s3_db_bucket_path']
    
    dump_name = dump_database
    
    if bucket_path.blank?
      s3_dump_name = dump_name
    else
      s3_dump_name = bucket_path + "/"+ dump_name
    end
    
    puts "[#{Time.now}] dump finished. db/#{dump_name} created"
    puts "[#{Time.now}] backing up dump to S3."
   
    require 's3'
   
    service = S3::Service.new(:access_key_id =>key_id, :secret_access_key => secret)
    bucket = service.buckets.find(bucket_name)
    
    new_object = bucket.objects.build(s3_dump_name)
    new_object.acl = :private
    new_object.content = open("db/#{dump_name}")
    new_object.save
    
    puts "[#{Time.now}] S3 backup finished."
  end
  
end