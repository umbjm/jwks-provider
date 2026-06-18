# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"
require "openssl"
require "jose"

module JwksProvider
  module Generators
    class KeysGenerator < Rails::Generators::Base
      desc "Generates RSA private/public key pairs for staging and production environments."

      KEY_BITS = 2048
      ENVS = %w[staging production].freeze

      def generate_key_pairs
        ENVS.each do |env|
          private_key_path = "config/keys/#{env}/private_key.pem"
          public_key_path  = "config/keys/#{env}/public_key.pem"
          jwks_path        = "config/keys/#{env}/jwks.json"

          if File.exist?(private_key_path)
            say "Skipping #{env}: #{private_key_path} already exists.", :yellow
            next
          end

          say "Generating #{env} RSA #{KEY_BITS}-bit key pair...", :green

          rsa_key = OpenSSL::PKey::RSA.generate(KEY_BITS)

          create_file private_key_path, rsa_key.to_pem
          create_file public_key_path,  rsa_key.public_key.to_pem

          jwk = JOSE::JWK.from_key(rsa_key)
          jwk_map = jwk.to_map
          jwk_map["kid"] = "#{env}-#{Time.now.to_i}"
          jwk_map["use"] = "sig"
          jwk_map["alg"] = "RS256"

          public_jwk = jwk_map.reject { |k, _| %w[d p q dp dq qi].include?(k) }
          create_file jwks_path, JSON.pretty_generate({ keys: [public_jwk] })
        end

        update_gitignore
      end

      private

      def update_gitignore
        gitignore = ".gitignore"
        entries = [
          "config/keys/staging/private_key.pem",
          "config/keys/production/private_key.pem"
        ]

        entries.each do |entry|
          append_to_file gitignore, "\n#{entry}" unless File.read(gitignore).include?(entry)
        end
      end
    end
  end
end
