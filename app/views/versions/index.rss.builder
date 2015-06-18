xml.channel do
  xml.title @title
  xml.description "Feed for recent activity"
  xml.link formatted_activity_url
  for version in @versions

    if version.item_type.downcase == "map" 
      typename = "Map"
    elsif version.item_type.downcase == "gcp" 
      typename = "Control Point" 
    end 

    xml.item do
      user = User.find_by_id(version.whodunnit)
      
      if user && user.login
        changed_by = "  by " + user.login.capitalize 
      else
        changed_by = " by -- "
      end

      xml.title typename + ' ' + version.item_id.to_s + " changed" + changed_by
      
      xml.description "Action: "+ version.event.gsub(/\W/, "")  + "\n" + version.changeset.inspect +  "\n Version: "+ version.index.to_s 
        
      xml.pubDate version.created_at.to_s(:rfc822)
      xml.link activity_details_url(:id => version)

      xml.guid
    end

  end
end
