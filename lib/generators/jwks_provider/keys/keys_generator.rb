# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"
require "openssl"

module JwksProvider
  module Generators
    class KeysGenerator < Rails::Generators::Base
      desc "Generates RSA private/public key pairs for staging and production environments."

      KEY_BITS = 2048
      ENVS = %w[staging production].freeze

      def generate_key_pairs
        ENVS.each do |env|
          private_key_path = "config/keys/#{env}/enc_key.pem"
          public_key_path  = "config/keys/#{env}/sig_key.pem"

          if File.exist?(private_key_path)
            say "Skipping #{env}: #{private_key_path} already exists.", :yellow
            next
          end

          say "Generating #{env} RSA #{KEY_BITS}-bit key pair...", :green

          rsa_key = OpenSSL::PKey::RSA.generate(KEY_BITS)

          create_file private_key_path, rsa_key.to_pem
          create_file public_key_path,  rsa_key.public_key.to_pem
        end
      end
    end
  end
end
