module Lockdown
  class Database
    class << self
      # This is very basic and could be handled better using orm specific
      # functionality, but I wanted to keep it generic to avoid creating 
      # an interface for each the different orm implementations. 
      # We'll see how it works...
      def sync_with_db

        @permissions = Lockdown::System.permissions.keys
        @user_groups = Lockdown::System.user_groups.keys

        create_new_permissions

        delete_extinct_permissions
      
        maintain_user_groups
      rescue Exception => e
        puts ">> Lockdown sync failed: #{e}" 
      end

      private

      # Create permissions not found in the database
      def create_new_permissions
        @permissions.each do |key|
          next if Lockdown::System.permission_assigned_automatically?(key)
          str = Lockdown.get_string(key)
          p = Permission.find(:first, :conditions => ["name = ?", str])
          unless p
            puts ">> Lockdown: Permission not found in db: #{str}, creating."
            Permission.create(:name => str)
          end
        end
      end

      # Delete the permissions not found in init.rb
      def delete_extinct_permissions
        db_perms = Permission.find(:all).dup
        db_perms.each do |dbp|
          unless @permissions.include?(Lockdown.get_symbol(dbp.name))
            puts ">> Lockdown: Permission no longer in init.rb: #{dbp.name}, deleting."
            Lockdown.database_execute("delete from permissions_user_groups where permission_id = #{dbp.id}")
            dbp.destroy
          end
        end
      end

      def maintain_user_groups
        # Create user groups not found in the database
        @user_groups.each do |key|
          str = Lockdown.get_string(key)
          unless ug = UserGroup.find(:first, :conditions => ["name = ?", str])
            create_user_group(str)
          else
            # Remove permissions from user group not found in init.rb
            ug.permissions.each do |perm|
              perm_sym = Lockdown.get_symbol(perm)
              perm_string = Lockdown.get_string(perm)
              unless @user_groups[key].include?(perm_sym)
                puts ">> Lockdown: Permission: #{perm_string} no longer associated to User Group: #{ug.name}, deleting."
                ug.permissions.delete(perm)
              end
            end

            # Add in permissions from init.rb not found in database
            @user_groups[key].each do |perm|
              perm_string = Lockdown.get_string(perm)
              found = false
              # see if permission exists
              ug.permissions.each do |p|
                found = true if Lockdown.get_string(p) == perm_string 
              end
              # if not found, add it
              unless found
                puts ">> Lockdown: Permission: #{perm_string} not found for User Group: #{ug.name}, adding it."
                p = Permission.find(:first, :conditions => ["name = ?", perm_string])
                ug.permissions << p
              end
            end
          end
        end
      end

      def create_user_group(name_str)
        puts ">> Lockdown: UserGroup not in the db: #{name_str}, creating."
        ug = UserGroup.create(:name => name_str)
        #Inefficient, definitely, but shouldn't have any issues across orms.
        Lockdown::System.permissions_for_user_group(key) do |perm|
          p = Permission.find(:first, :conditions => ["name = ?", Lockdown.get_string(perm)])
          Lockdown.database_execute <<-SQL 
                insert into permissions_user_groups(permission_id, user_group_id)
                values(#{p.id}, #{ug.id})
          SQL
        end
      end
    end # class block
  end # Database
end #Lockdown