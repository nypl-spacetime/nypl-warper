class UserMailer < ActionMailer::Base
  default from: APP_CONFIG['email']

  def disabled_change_password(user)
    @user = user
    @subject = "#{APP_CONFIG['site_name']} You account is disabled until you change your password"
    mail(to: @user.email, subject: @subject)
  end

  def new_registration(user)
    @user = user
    @subject = "Welcome to #{APP_CONFIG['site_name']} #{@user.login}"
    mail(to: @user.email, subject: @subject)
  end
  
  #
  # sends an abuse report to add enabled administrators with email if the flag is about a user who exists
  #
  def flag_report(flag)
    @flag = flag
    
    if @flag.flaggable_type == "User"
      if User.exists?(:id => @flag.flaggable_id)
        @flagged_user = User.select(:login, :id).find_by_id(@flag.flaggable_id)
        @admin_emails = User.joins(:roles).where('enabled = true and provider is null and roles.name = ?', 'administrator').pluck(:email)
        @subject = "#{APP_CONFIG['site_name']} : New Possible Malicious User Flag Report for User: #{@flagged_user.login} because #{@flag.reason}"
        
        mail(:to => @admin_emails, :subject =>@subject )
      end
    end

  end

end
