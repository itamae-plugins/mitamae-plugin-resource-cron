# Ported from:
# https://github.com/chef/chef/blob/v12.13.37/lib/chef/provider/cron.rb
module ::MItamae
  module Plugin
    module ResourceExecutor
      class Cron < ::MItamae::ResourceExecutor::Base
        SPECIAL_TIME_VALUES = [:reboot, :yearly, :annually, :monthly, :weekly, :daily, :midnight, :hourly]
        CRON_ATTRIBUTES = [:minute, :hour, :day, :month, :weekday, :time, :command, :mailto, :path, :shell, :home, :environment]

        CRON_PATTERN = /\A([-0-9*,\/]+)\s([-0-9*,\/]+)\s([-0-9*,\/]+)\s([-0-9*,\/]+|[a-zA-Z]{3})\s([-0-9*,\/]+|[a-zA-Z]{3})\s(.*)/
        SPECIAL_PATTERN = /\A(@(#{SPECIAL_TIME_VALUES.join('|')}))\s(.*)/
        ENV_PATTERN = /\A(\S+)=(\S*)/

        # Overriding https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L31-L33,
        # and called at https://github.com/itamae-kitchen/mitamae/blob/v1.6.3/mrblib/mitamae/resource_executor/base.rb#L85
        # to reflect `desired` states which are not met in `current`.
        def apply
          if desired.cron_exists
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
            desired.cron_exists = true
          when :delete
            desired.cron_exists = false
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
          case action
          when :create, :delete
            @cron_empty = false # using ivar because there's no need to expose this to log unlike `current.cron_exists`.
            load_current_resource(current)
          else
            raise NotImplementedError, "unhandled action: '#{action}'"
          end
        end

        # https://github.com/chef/chef/blob/v12.13.37/lib/chef/provider/cron.rb#L49-L95
        def load_current_resource(current)
          current.environment = {}
          current.user = desired.user
          current.cron_exists = false
          if crontab = read_crontab
            cron_found = false
            crontab.each_line do |line|
              case line.chomp
              when "# Chef Name: #{@resource.resource_name}"
                MItamae.logger.debug("Found cron '#{@resource.resource_name}'")
                cron_found = true
                current.cron_exists = true
                next
              when ENV_PATTERN
                set_environment_var($1, $2) if cron_found
                next
              when SPECIAL_PATTERN
                if cron_found
                  current.time = $2.to_sym
                  current.command = $3
                  cron_found = false
                end
              when CRON_PATTERN
                if cron_found
                  current.minute = $1
                  current.hour = $2
                  current.day = $3
                  current.month = $4
                  current.weekday = $5
                  current.command = $6
                  cron_found = false
                end
                next
              else
                cron_found = false # We've got a Chef comment with no following crontab line
                next
              end
            end
            MItamae.logger.debug("Cron '#{@resource.resource_name}' not found") unless current.cron_exists
          else
            MItamae.logger.debug("Cron empty for '#{desired.user}'")
            @cron_empty = true
          end
        end

        def cron_different?
          CRON_ATTRIBUTES.any? do |cron_var|
            desired.send(cron_var) != current.send(cron_var)
          end
        end

        # https://github.com/chef/chef/blob/v12.13.37/lib/chef/provider/cron.rb#L103-L161
        def action_create
          crontab = String.new
          newcron = String.new
          cron_found = false

          newcron = get_crontab_entry

          if current.cron_exists
            unless cron_different?
              MItamae.logger.debug("Skipping existing cron entry '#{@resource.resource_name}'")
              return
            end
            read_crontab.each_line do |line|
              case line.chomp
              when "# Chef Name: #{@resource.resource_name}"
                cron_found = true
                next
              when ENV_PATTERN
                crontab << line unless cron_found
                next
              when SPECIAL_PATTERN
                if cron_found
                  cron_found = false
                  crontab << newcron
                  next
                end
              when CRON_PATTERN
                if cron_found
                  cron_found = false
                  crontab << newcron
                  next
                end
              else
                if cron_found # We've got a Chef comment with no following crontab line
                  crontab << newcron
                  cron_found = false
                end
              end
              crontab << line
            end

            # Handle edge case where the Chef comment is the last line in the current crontab
            crontab << newcron if cron_found

            write_crontab crontab
            MItamae.logger.info("#{@resource.resource_name} updated crontab entry")

          else
            crontab = read_crontab unless @cron_empty
            crontab << newcron

            write_crontab crontab
            MItamae.logger.info("#{@resource.resource_name} added crontab entry")
          end
        end

        def action_delete
          if current.cron_exists
            crontab = String.new
            cron_found = false
            read_crontab.each_line do |line|
              case line.chomp
              when "# Chef Name: #{@resource.resource_name}"
                cron_found = true
                next
              when ENV_PATTERN
                next if cron_found
              when SPECIAL_PATTERN
                if cron_found
                  cron_found = false
                  next
                end
              when CRON_PATTERN
                if cron_found
                  cron_found = false
                  next
                end
              else
                # We've got a Chef comment with no following crontab line
                cron_found = false
              end
              crontab << line
            end
            description = cron_found ? "remove #{@resource.resource_name} from crontab" :
              "save unmodified crontab"
            write_crontab crontab
            MItamae.logger.info("#{@resource.resource_name} deleted crontab entry")
          end
        end

        def set_environment_var(attr_name, attr_value)
          if %w{MAILTO PATH SHELL HOME}.include?(attr_name)
            current.send("#{attr_name.downcase}=", attr_value)
          else
            current.environment = current.environment.merge(attr_name => attr_value)
          end
        end

        # https://github.com/chef/chef/blob/v12.13.37/lib/chef/provider/cron.rb#L209-L218
        def read_crontab
          crontab = nil
          if (command = @runner.run_command("crontab -l -u #{desired.user}", error: false)).exit_status == 0
            crontab = command.stdout
          end
          if command.exit_status > 1
            raise "Error determining state of #{@resource.resource_name}, exit: #{command.exit_status}"
          end
          crontab
        end

        def write_crontab(crontab)
          write_exception = false
          f = Tempfile.open('mitamae-plugin-resource-cron')
          f.write(crontab)
          command = @runner.run_command("cat #{f.path.shellescape} | crontab -u #{desired.user} -")
          f.close
          if command.exit_status > 0
            raise "Error updating state of #{@resource.resource_name}, exit: #{command.exit_status}"
          end
        end

        def get_crontab_entry
          newcron = ""
          newcron << "# Chef Name: #{@resource.resource_name}\n"
          [ :mailto, :path, :shell, :home ].each do |v|
            newcron << "#{v.to_s.upcase}=\"#{desired.send(v)}\"\n" if desired.send(v)
          end
          desired.environment.each do |name, value|
            newcron << "#{name}=#{value}\n"
          end
          if desired.time
            newcron << "@#{desired.time} #{desired.command}\n"
          else
            newcron << "#{desired.minute} #{desired.hour} #{desired.day} #{desired.month} #{desired.weekday} #{desired.command}\n"
          end
          newcron
        end
      end
    end
  end
end
