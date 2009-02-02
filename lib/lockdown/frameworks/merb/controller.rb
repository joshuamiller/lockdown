module Lockdown
  module Frameworks
    module Merb
      module Controller

        def available_actions(klass)
          klass.callable_actions.keys
        end

        def controller_name(klass)
          klass.controller_name
        end
        
        # Locking methods
        module Lock
          def self.included(base)
            base.class_eval do 
              include Lockdown::Frameworks::Merb::Controller::Lock::InstanceMethods
            end

            base.before :set_current_user
            base.before :configure_lockdown
            base.before :check_request_authorization
          end

          module InstanceMethods
            def self.included(base)
              base.class_eval do
                include Lockdown::CoreController
              end
            end

            def sent_from_uri
              request.uri
            end

            def authorized?(path)
              return true if current_user_is_admin?

              path_allowed?(path)
            end
          
            # Can log Error => e if desired, I don't desire to now.
            # For now, just send home, but will probably make this configurable
            def access_denied(e)
              redirect Lockdown::System.fetch(:access_denied_path)
            end
          
            def path_from_hash(hsh)
              return hsh if hsh.is_a?(String)
              hsh = hsh.to_hash if hsh.is_a?(Mash)
              hsh['controller'].to_s + "/" + hsh['action'].to_s
            end
          
            def redirect_back_or_default(default)
              session[:prevpage] ? redirect(session[:prevpage]) : redirect(default)
            end
          end # InstanceMethods
        end # Lock
      end # Controller
    end # Merb
  end # Frameworks
end # Lockdown
