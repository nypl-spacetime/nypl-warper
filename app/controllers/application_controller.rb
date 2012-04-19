# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  filter_parameter_logging :password
  include AuthenticatedSystem
 
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '02fd3a68fbbf6bb592746ba9dd1e79d6'
  
  audit Map, Gcp #:only => [:create, :update, :destroy]
  # if we want to audit User, then need to comment out attr_protected :audit_ids in acts_as_audited/lib/acts_as_audited.rb line 66 
  # it's apparently there for security, http://opensoul.org/2006/9/7/acts_as_audited-security-update 
  
 
layout 'application'
   


end

