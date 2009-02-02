module Lockdown
  module Frameworks
    module Merb
      module View
        def self.included(base)
          base.class_eval do
            alias_method  :link_to_open,  :link_to
            alias_method  :link_to,  :link_to_secured
          end
        end

        def link_to_secured(name, url = '', options = {})
          if authorized? url
            return link_to_open(name, url, options)
          end
          return ""
        end

        def link_to_or_show(name, url = '', options = {})
          lnk = link_to(name, url , options)
          lnk.length == 0  ? name : lnk
        end

        def links(*lis)
          rvalue = []
          lis.each{|link| rvalue << link if link.length > 0 }
          rvalue.join(" | ")
        end
      end # View
    end # Merb
  end # Frameworks
end # Lockdown
