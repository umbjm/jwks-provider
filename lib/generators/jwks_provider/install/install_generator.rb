# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"

module JwksProvider
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Installs jwks-provider: generates EC key pairs, initializer, controller, and route."

      class_option :app_name,
                   type: :string,
                   desc: "Application name used in KID aliases (e.g. my-app → alias/my-app-id-token-...)"

      def set_app_name
        @app_name = options[:app_name] || ask("Enter application name for KID aliases (e.g. my-app):")
        raise Thor::Error, "app_name cannot be blank" if @app_name.strip.empty?
      end

      def generate_keys
        say "Generating EC key pairs for staging and production...", :green
        invoke "jwks_provider:keys"
      end

      def create_initializer
        create_file "config/initializers/jwks_provider.rb", <<~RUBY
          JwksProvider.app_name = "#{@app_name}"
        RUBY
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
