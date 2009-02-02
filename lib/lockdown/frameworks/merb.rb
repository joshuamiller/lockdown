require File.join(File.dirname(__FILE__), "merb", "controller")
require File.join(File.dirname(__FILE__), "merb", "view")

module Lockdown
  module Frameworks
    module Merb
      class << self
        def use_me?
          Object.const_defined?("Merb") && ::Merb.const_defined?("AbstractController")
        end

        def included(mod)
          mod.extend Lockdown::Frameworks::Merb::Environment
          mixin
        end

        def mixin
          Lockdown.controller_parent.class_eval do
            include Lockdown::Frameworks::Merb::Controller::Lock
          end
          Lockdown.view_helper.class_eval do
            include Lockdown::Frameworks::Merb::View
          end
          Lockdown::System.class_eval do
            extend Lockdown::Frameworks::Merb::System
          end
        end
      end # class block


      module Environment
        def project_root
          ::Merb.root
        end

        def controller_parent
          ::Merb::Controller 
        end

        def view_helper
          ::Merb::AssetsMixin
        end

        def controller_class_name(str)
          if str.include?("__")
            str.split("__").collect{|p| Lockdown.camelize(p)}.join("::")
          else
            Lockdown.camelize(str)
          end
        end
      end

      module System
        include Lockdown::Frameworks::Merb::Controller

        def skip_sync?
          Lockdown::System.fetch(:skip_db_sync_in).include?(Merb.environment)
        end

        def load_controller_classes
          @controller_classes = {}
         
          maybe_load_framework_controller_parent
        
          Dir.chdir("#{Lockdown.project_root}/app/controllers") do
            Dir["**/*.rb"].sort.each do |c|
              next if c == "application.rb"
              lockdown_load(c) 
            end
          end
        end
 
        def maybe_load_framework_controller_parent
          load("application.rb") unless const_defined?("Application")
        end

        def lockdown_load(file)
          klass = Lockdown.class_name_from_file(file)
          @controller_classes[klass] = Lockdown.qualified_const_get(klass) 
        end
      end # System
    end # Merb
  end # Frameworks
end # Lockdown
