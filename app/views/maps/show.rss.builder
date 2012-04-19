xml.channel do
  xml.title "Map #{@map.id}"
  xml.link url_for(:id=>@map.id, :format=>"rss", :only_path=>false)
  xml.description ""
  xml.item do
    xml.title @map.title
    xml.description @map.description
    xml.link url_for(:id=>@map.id, :only_path=>false)
    xml.guid
  end
end
