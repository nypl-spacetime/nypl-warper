module AuditsHelper
  
  
  def formatted_action(action)
    action.gsub(/\W/, "").titleize
  end

  
end
