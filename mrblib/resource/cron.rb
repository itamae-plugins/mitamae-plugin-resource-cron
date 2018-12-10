# Ported from: https://github.com/chef/chef/blob/v12.13.37/lib/chef/resource/cron.rb
module ::MItamae
  module Plugin
    module Resource
      # List of original attributes: https://github.com/chef/chef/blob/v12.13.37/lib/chef/resource/cron.rb#L26-L48
      class Cron < ::MItamae::Resource::Base
        define_attribute :action, default: :create
        define_attribute :command, type: String, default_name: true

        define_attribute :minute, type: String, default: '*'
        define_attribute :hour, type: String, default: '*'
        define_attribute :day, type: String, default: '*'
        define_attribute :month, type: String, default: '*'
        define_attribute :weekday, type: String, default: '*'
        define_attribute :user, type: String, default: 'root'

        define_attribute :mailto, type: String
        define_attribute :path, type: String
        define_attribute :shell, type: String
        define_attribute :home, type: String
        define_attribute :time, type: String
        define_attribute :environment, type: Hash, default: {}

        self.available_actions = [:create, :delete]
      end
    end
  end
end
