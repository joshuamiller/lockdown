module Lockdown
  module Orms
    module DataMapper
      class << self
        def use_me?
          Object.const_defined?("DataMapper") && DataMapper.const_defined?("Base")
        end

        def included(mod)
          mod.extend Lockdown::Orms::Datamapper::Helper
          mixin
        end

        def mixin
          orm_parent.class_eval do
            include Lockdown::Orm::DataMapper::Stamps
          end
        end
      end # class block

      module Helper
        def orm_parent
          ::DataMapper::Base
        end

        #TODO: These may be called from DataMapper::Base or DataMapper, not sure
        #FIXME: If Datamapper is correct, need ::DataMapper
        def database_execute(query)
          DataMapper.database.execute(query)
        end

        def database_query(query)
          DataMapper.database.query(query)
        end

        def database_table_exists?(klass)
          DataMapper.database.table_exists?(klass)
        end
      end

      module Stamps
        def self.included(base)
          base.class_eval do
            alias_method :create_without_stamps,  :create
            alias_method :create,  :create_with_stamps
            alias_method :update_without_stamps,  :update
            alias_method :update,  :update_with_stamps
          end
        end

        def current_profile_id
          Thread.current[:profile_id]
        end

        def create_with_stamps
          profile_id = current_profile_id || Profile::SYSTEM
          self[:created_by] = profile_id if self.respond_to?(:created_by) 
          self[:updated_by] = profile_id if self.respond_to?(:updated_by) 
          create_without_stamps
        end
                  
        def update_with_stamps
          profile_id = current_profile_id || Profile::SYSTEM
          self[:updated_by] = profile_id if self.respond_to?(:updated_by)
          update_without_stamps
        end
      end
    end
  end
end
