# frozen_string_literal: true

require "openssl"
require "jose"
require "json"

module Jwks
  module Provider
    module KeySet
      SUPPORTED_ENVS = %w[staging production].freeze

      class << self
        def for(env)
          env = env.to_s
          raise ArgumentError, "Unsupported env: #{env}" unless SUPPORTED_ENVS.include?(env)

          private_key_pem = File.read(private_key_path(env))
          JOSE::JWK.from_key(OpenSSL::PKey::RSA.new(private_key_pem))
        end

        def public_jwks(env)
          env = env.to_s
          jwks_file = jwks_path(env)

          if File.exist?(jwks_file)
            JSON.parse(File.read(jwks_file))
          else
            jwk = self.for(env)
            map = jwk.to_map
            public_map = map.reject { |k, _| %w[d p q dp dq qi].include?(k) }
            { keys: [public_map] }
          end
        end

        def verify_jwt(token, env)
          jwk = self.for(env)
          JOSE::JWT.verify(jwk, token)
        end

        private

        def private_key_path(env)
          Rails.root.join("config", "keys", env, "private_key.pem")
        end

        def jwks_path(env)
          Rails.root.join("config", "keys", env, "jwks.json")
        end
      end
    end
  end
end
