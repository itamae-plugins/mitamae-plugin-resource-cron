# Ported from:
# https://github.com/chef/chef/blob/v12.13.37/lib/chef/provider/cron.rb
module ::MItamae
  module Plugin
    module ResourceExecutor
      class Cron < ::MItamae::ResourceExecutor::Base
        # Overriding https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L31-L33,
        # and called at https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L85
        # to reflect `desired` states which are not met in `current`.
        def apply
          if desired.created
            action_create
          else
            raise NotImplementedError, 'only create action is supported for now'
          end
        end

        private

        # Overriding https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L147-L149,
        # and called at https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L67-L68
        # to map specified action to attributes to be modified. Attributes specified in recipes are already set to `desired`.
        # So we don't need to set them manually.
        # https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L142.
        #
        # Difference between `desired` and `current` are aimed to be changed in #apply.
        def set_desired_attributes(desired, action)
          case action
          when :create
            desired.created = true
          when :delete
            desired.created = false
          else
            raise NotImplementedError, "unhandled action: '#{action}'"
          end
        end

        # Overriding https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L135-L137,
        # and called at https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L70-L71
        # to map the current machine status to attributes. Probably similar to Chef's #load_current_resource.
        #
        # current_attributes which are the same as desired_attributes will NOT be touched in #apply.
        def set_current_attributes(current, action)
          load_current_resource
          case action
          when :create, :delete
            current.created = false
          else
            raise NotImplementedError, "unhandled action: '#{action}'"
          end
        end

        def action_create
          MItamae.logger.info("action_create")
        end
      end
    end
  end
end
