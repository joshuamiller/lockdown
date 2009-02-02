require File.join(File.dirname(__FILE__), "session")

Lockdown::System.configure do

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Configuration Options
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Options with defaults:
  #
  # Set timeout to 1 hour:
  #       options[:session_timeout] = (60 * 60)
  #
  # Call method when timeout occurs (method must be callable by controller):
  #       options[:session_timeout_method] = :clear_session_values
  #
  # Set system to logout if unauthorized access is attempted:
  #       options[:logout_on_access_violation] = false
  #
  # Set redirect to path on unauthorized access attempt:
  #       options[:access_denied_path] = "/"
  #
  # Set redirect to path on successful login:
  #       options[:successful_login_path] = "/"
  #
  # If deploying to a subdirectory, set that here. Defaults to nil
  #       options[:subdirectory] = "blog"
  #       *Notice: Do not add leading or trailing slashes,
  #                Lockdown will handle this
  #
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Define permissions
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #
  # set_permission(:product_management, all_methods(:products))
  #
  # :product_management is the name of the permission which is later
  # referenced by the set_user_group method
  #
  # :all_methods(:products) will return an array of all controller actions
  # for the products controller
  #
  # If you need to reference a namespaced controller use two underscores:
  # :admin__products would tell lockdown to look for:
  # app/controllers/admin/products_controller.rb
  #
  # if products is your standard RESTful resource you'll get:
  #   ["products/index , "products/show",
  #    "products/new", "products/edit",
  #    "products/create", "products/update",
  #    "products/destroy"]
  #
  # You can pass multiple parameters to concat permissions such as:
  #      
  #	  set_permission(:security_management,all_methods(:users),
  #                                       all_methods(:user_groups),
  #                                       all_methods(:permissions) )
  #
  # In addition to all_methods(:controller) there are:
  #
  #       only_methods(:controller, :only_method_1, :only_method_2)
  #
  #       all_except_methods(:controller, :except_method_1, :except_method_2)
  #
  # Some other sample permissions:
  # 
  #  set_permission(:sessions, all_methods(:sessions))
  #  set_permission(:my_account, only_methods(:users, :edit, :update, :show))
  # 
  # Define your permissions here:

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Built-in user groups
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #  You can assign the above permission to one of the built-in user groups
  #  by using the following:
  # 
  #  To allow public access on the permissions :sessions and :home:
  #    set_public_access :sessions, :home
  #     
  #  Restrict :my_account access to only authenticated users:
  #    set_protected_access :my_account
  #
  # Define the built-in user groups here:

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Define user groups
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  #
  #  set_user_group(:catalog_management, :category_management, 
  #                                      :product_management) 
  #
  #  :catalog_management is the name of the user group
  #  :category_management and :product_management refer to permission names
  #
  # 
  # Define your user groups here:

end 
