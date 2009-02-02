module Lockdown
  class InvalidRuleAssignment < StandardError; end

  module Rules
    attr_accessor :options
    attr_accessor :permissions
    attr_accessor :user_groups
    attr_accessor :controller_classes

    attr_reader :protected_access 
    attr_reader :public_access

    attr_reader :permission_objects
 
    def set_defaults
      @permissions  = {}
      @user_groups  = {}
      @options      = {}

      @permission_objects = {}

      @controller_classes = []
      @public_access      = []
      @protected_access   = []

      @options = {
        :session_timeout => (60 * 60),
        :logout_on_access_violation => false,
        :access_denied_path => "/",
        :successful_login_path => "/",
        :subdirectory => nil,
        :skip_db_sync_in => ["test"]
      }
    end

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # =Rule defining methods.  e.g. Methods used in lib/lockdown/init.rb
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Creates new permission object 
    #   Refer to the Permission object for the full functionality
    def set_permission(name)
      @permission_objects[name] = Lockdown::Permission.new(name)
    end

    # Defines public access by the permission symbols
    #
    # ==== Example
    #   set_public_access(:permission_one, :permission_two)
    #
    def set_public_access(*perms)
      perms.each do |perm_symbol|
        perm = permission_objects.find{|name, pobj| pobj.name == perm_symbol}
        if perm
          perm[1].set_as_public_access 
        else
          msg = "Permission not found: #{perm_symbol}"
          raise InvalidRuleAssigment, msg
        end
      end
    end

    # Defines protected access by the permission symbols
    #
    # ==== Example
    #   set_public_access(:permission_one, :permission_two)
    #
    def set_protected_access(*perms)
      perms.each do |perm_symbol|
        perm = permission_objects.find{|name, pobj| pobj.name == perm_symbol}
        if perm
          perm[1].set_as_protected_access 
        else
          msg = "Permission not found: #{perm_symbol}"
          raise InvalidRuleAssigment, msg
        end
      end
    end

    def set_user_group(name, *perms)
      user_groups[name] ||= []
      perms.each do |perm|
        user_groups[name].push(perm)
      end
    end
 
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # =Convenience methods for permissions and user groups
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    # Returns array of permission names as symbols
    def get_permissions
      permissions.keys
    end

    # Is the permission defined?
    def permission_exists?(permission_symbol)
      get_permissions.include?(permission_symbol)
    end

    # Returns array of user group names as symbols
    def get_user_groups
      user_groups.keys
    end

    # Is the user group defined?
    def user_group_exists?(user_group_symbol)
      get_user_groups.include?(user_group_symbol)
    end


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # =Convenience methods for permissions and user groups
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Pass in a user object to be associated to the administrator user group 
    # The group will be created if it doesn't exist
    def make_user_administrator(usr)
      usr.user_groups << UserGroup.
        find_or_create_by_name(Lockdown.administrator_group_string)
    end


    # Determine if the user group is defined in init.rb
    def has_user_group?(ug)
      sym = Lockdown.get_symbol(ug)
      return true if sym == Lockdown.administrator_group_symbol
      user_group_exists?(sym)
    end

    # Returns array of controller/action values all logged in users can access.
    def standard_authorized_user_rights
      public_access + protected_access 
    end

    # Return array of controller/action values user can access.
    def access_rights_for_user(usr)
      return unless usr
      return :all if administrator?(usr)

      rights = standard_authorized_user_rights
        
      usr.user_groups.each do |grp|
        permissions_for_user_group(grp) do |perm|
          rights += access_rights_for_permission(perm) 
        end
      end
      rights
    end

    # Return array of controller/action for a permission
    def access_rights_for_permission(perm)
      sym = Lockdown.get_symbol(perm)

      permissions[sym]
    rescue 
      raise SecurityError, "Permission requested is not defined: #{sym}"
    end


    # Test user for administrator rights
    def administrator?(usr)
      user_has_user_group?(usr, Lockdown.administrator_group_symbol)
    end

    # Pass in user object and symbol for name of user group
    def user_has_user_group?(usr, sym)
      usr.user_groups.any? do |ug|
        Lockdown.convert_reference_name(ug.name) == sym
      end
    end

    # Use this for the management screen to restrict user group list to the
    # user.  This will prevent a user from creating a user with more power than
    # him/her self.
    def user_groups_assignable_for_user(usr)
      return [] if usr.nil?
        
      if administrator?(usr)
        UserGroup.find_by_sql <<-SQL
          select user_groups.* from user_groups order by user_groups.name
        SQL
      else
        UserGroup.find_by_sql <<-SQL
            select user_groups.* from user_groups, user_groups_users
             where user_groups.id = user_groups_users.user_group_id
             and user_groups_users.user_id = #{usr.id}	 
             order by user_groups.name
        SQL
      end
    end

    # Similar to user_groups_assignable_for_user, this method should be
    # used to restrict users from creating a user group with more power than
    # they have been allowed.
    def permissions_assignable_for_user(usr)
      return [] if usr.nil?
      if administrator?(usr)
        get_permissions.collect do |k| 
          Permission.find_by_name(Lockdown.get_string(k))
        end.compact
      else
        user_groups_assignable_for_user(usr).collect do
          |g| g.permissions
        end.flatten.compact
      end
    end

    def permissions_for_user_group(ug)
      sym = Lockdown.get_symbol(ug)
      perm_array = []  

      if has_user_group?(sym)
        permissions = user_groups[sym] || []
      else
        permissions = ug.permissions
      end


      permissions.each do |perm|
        perm_sym = Lockdown.get_symbol(perm)

        unless permission_exists?(perm_sym)
          msg = "Permission associated to User Group is invalid: #{perm}"
          raise SecurityError, msg
        end

        if block_given?
          yield perm_sym
        else
          perm_array << perm_sym
        end
      end

      perm_array 
    end

    def process_rules
      parse_permissions
      validate_user_groups
    end

    private

    def parse_permissions
      permission_objects.each do |name, perm|
        @permissions[perm.name] ||= []
        perm.controllers.collect do |controller|
          @permissions[perm.name] << controller.methods
        end
      end
    end

    def validate_user_groups
      user_groups.each do |user_group, perms|
        perms.each do |perm|
          unless permission_exists?(perm)
            msg ="User Group: #{user_group}, permission not found: #{perm}"
            raise InvalidRuleAssignment, msg
          end
        end
      end
    end
  end
end
