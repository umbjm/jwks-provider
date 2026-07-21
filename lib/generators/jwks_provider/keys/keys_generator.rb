# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"
require "openssl"

module JwksProvider
  module Generators
    class KeysGenerator < Rails::Generators::Base
      desc "Generates EC (prime256v1) key pairs for staging and production environments."

      EC_CURVE = "prime256v1"
      ENVS = %w[stg prd].freeze

      def generate_key_pairs
        ENVS.each do |env|
          private_key_path = "config/keys/enc_key_#{env}.pem"
          public_key_path  = "config/keys/sig_key_#{env}.pem"

          if File.exist?(private_key_path)
            say "Skipping #{env}: #{private_key_path} already exists.", :yellow
            next
          end

          say "Generating #{env} EC #{EC_CURVE} key pair...", :green

          ec_key = OpenSSL::PKey::EC.generate(EC_CURVE)

          create_file private_key_path, ec_key.to_pem
          create_file public_key_path,  ec_key.public_to_pem
        end
      end
    end
  end
end
