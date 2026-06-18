# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"

module JwksProvider
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs jwks-provider: generates RSA key pairs, controller concern, controller, and route."

      def generate_keys
        say "Generating RSA key pairs for staging and production...", :green
        invoke "jwks_provider:keys"
      end

      def copy_concern
        template "json_web_key.rb", "app/controllers/concerns/json_web_key.rb"
      end

      def copy_controller
        template "jwks_controller.rb", "app/controllers/jwks_controller.rb"
      end

      def inject_routes
        route 'get ".well-known/jwks", to: "jwks#index"'
      end
    end
  end
end
