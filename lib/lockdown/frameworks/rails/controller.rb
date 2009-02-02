module Lockdown
  module Frameworks
    module Rails
      module Controller
        
        def available_actions(klass)
          if klass.respond_to?(:action_methods)
            klass.action_methods
          else
            klass.public_instance_methods - klass.hidden_actions
          end
        end

        def controller_name(klass)
          klass.controller_name
        end

        # Locking methods
        module Lock
          def self.included(base)
            base.class_eval do
              include Lockdown::Frameworks::Rails::Controller::Lock::InstanceMethods

              helper_method :authorized?
            end

            base.before_filter do |c|
              c.set_current_user
              c.configure_lockdown
              c.check_request_authorization
            end


            base.filter_parameter_logging :password, :password_confirmation
      
            base.rescue_from SecurityError, :with => proc{|e| access_denied(e)}
          end

          module InstanceMethods
            def self.included(base)
              base.class_eval do
                include Lockdown::CoreController
              end
            end

            def sent_from_uri
              request.request_uri
            end
        
            def authorized?(url, method = nil)
              return false unless url

              return true if current_user_is_admin?

              method ||= request.method

              url_parts = URI::split(url.strip)

              url = url_parts[5]

              return true if path_allowed?(url)

              begin
                hash = ActionController::Routing::Routes.recognize_path(url, :method => method)
                return path_allowed?(path_from_hash(hash)) if hash
              rescue Exception
                # continue on
              end

              # Passing in different domain
              return remote_url?(url_parts[2])
            end
      
            def access_denied(e)

              RAILS_DEFAULT_LOGGER.info "Access denied: #{e}"

              if Lockdown::System.fetch(:logout_on_access_violation)
                reset_session
              end
              respond_to do |format|
                format.html do
                  store_location
                  redirect_to Lockdown::System.fetch(:access_denied_path)
                  return
                end
                format.xml do
                  headers["Status"] = "Unauthorized"
                  headers["WWW-Authenticate"] = %(Basic realm="Web Password")
                  render :text => e.message, :status => "401 Unauthorized"
                  return
                end
              end
            end

            def path_from_hash(hash)
              hash[:controller].to_s + "/" + hash[:action].to_s
            end

            def remote_url?(domain = nil)
              return false if domain.nil? || domain.strip.length == 0
              request.host.downcase != domain.downcase
            end

            def redirect_back_or_default(default)
              session[:prevpage] ? redirect_to(session[:prevpage]) : redirect_to(default)
            end

          end # InstanceMethods
        end # Lock
      end # Controller
    end # Rails
  end # Frameworks
end # Lockdown

