require File.join(File.dirname(__FILE__), "rails", "controller")
require File.join(File.dirname(__FILE__), "rails", "view")

module Lockdown
  module Frameworks
    module Rails
      class << self
        def use_me?
          Object.const_defined?("ActionController") && ActionController.const_defined?("Base")
        end

        def included(mod)
          mod.extend Lockdown::Frameworks::Rails::Environment
          mixin
        end

        def mixin
          Lockdown.controller_parent.class_eval do
            include Lockdown::Frameworks::Rails::Controller::Lock
          end
          Lockdown.view_helper.class_eval do
            include Lockdown::Frameworks::Rails::View
          end
          Lockdown::System.class_eval do 
            extend Lockdown::Frameworks::Rails::System
          end
        end
      end # class block

      module Environment

        def project_root
          RAILS_ROOT
        end

        def init_file
          "#{project_root}/lib/lockdown/init.rb"
        end

        def controller_parent
          ActionController::Base
        end

        def view_helper
          ActionView::Base 
        end

        def controller_class_name(str)
          str = "#{str}Controller"
          if str.include?("__")
            str.split("__").collect{|p| Lockdown.camelize(p)}.join("::")
          else
            Lockdown.camelize(str)
          end
        end
      end

      module System
        include Lockdown::Frameworks::Rails::Controller

        def skip_sync?
          Lockdown::System.fetch(:skip_db_sync_in).include?(ENV['RAILS_ENV'])
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

          if ENV['RAILS_ENV'] != 'production'
            if ActiveSupport.const_defined?("Dependencies")
              ActiveSupport::Dependencies.clear
            else
              Dependencies.clear
            end
          end
        end

        def maybe_load_framework_controller_parent
          if ActiveSupport.const_defined?("Dependencies")
            ActiveSupport::Dependencies.require_or_load("application.rb")
          else
            Dependencies.require_or_load("application.rb")
          end
        end

        def lockdown_load(file)
          klass = Lockdown.class_name_from_file(file)
          if ActiveSupport.const_defined?("Dependencies")
            ActiveSupport::Dependencies.require_or_load(file)
          else
            Dependencies.require_or_load(file)
          end
          @controller_classes[klass] = Lockdown.qualified_const_get(klass) 
        end

      end # System
    end # Rails
  end # Frameworks
end # Lockdown
