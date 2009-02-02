module Lockdown
  module CoreController
    def configure_lockdown
      check_session_expiry
      store_location
    end

    def set_current_user
      login_from_basic_auth? unless logged_in?
      if logged_in?
        Thread.current[:profile_id] = current_profile_id
        Thread.current[:client_id] = current_client_id if respond_to? :current_client_id
      end
    end

    def check_request_authorization
      unless authorized?(path_from_hash(params))
        raise SecurityError, "Authorization failed for params #{params.inspect}"
      end
    end
    
    def path_allowed?(url)
      session[:access_rights] ||= Lockdown::System.public_access
      session[:access_rights].include?(url)
    end
      
    def check_session_expiry
      if session[:expiry_time] && session[:expiry_time] < Time.now
        nil_lockdown_values
        timeout_method = Lockdown::System.fetch(:session_timeout_method)
        if timeout_method.is_a?(Symbol) && self.respond_to?(timeout_method)
          send(timeout_method) 
        end
      end
      session[:expiry_time] = Time.now + Lockdown::System.fetch(:session_timeout)
    end
            
    def store_location
      if (request.method == :get) && (session[:thispage] != sent_from_uri)
        session[:prevpage] = session[:thispage] || ''
        session[:thispage] = sent_from_uri
      end
    end
    
    # Called from current_user.  Now, attempt to login by
    # basic authentication information.
    def login_from_basic_auth?
      username, passwd = get_auth_data
      if username && passwd
        set_session_user User.authenticate(username, passwd)
      end
    end
  
    @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
    # gets BASIC auth info
    def get_auth_data
      auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
      auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
      return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
    end
  end # CoreController
end # Lockdown
