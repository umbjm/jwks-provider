# frozen_string_literal: true

module JsonWebKey
  extend ActiveSupport::Concern

  def sig_key_set
    {
      "keys": [
        JWT::JWK.new(signing_key, kid: kid_sig_key, use: "sig", alg: "ES256").export,
        JWT::JWK.new(encryption_key, kid: kid_enc_key, use: "enc", alg: "ECDH-ES+A128KW").export
      ]
    }
  end

  def signing_key
    OpenSSL::PKey.read Rails.root.join("config/keys", env_key_path, "sig_key.pem").read
  end

  def encryption_key
    OpenSSL::PKey.read Rails.root.join("config/keys", env_key_path, "enc_key.pem").read
  end

  private

  def kid_sig_key
    "alias/<%= @app_name %>-id-token-#{kid_alias}-signing-key-kms-asymmetric-key"
  end

  def kid_enc_key
    "alias/<%= @app_name %>-id-token-#{kid_alias}-encryption-key-kms-asymmetric-key"
  end

  def kid_alias
    Rails.env.production? ? "prd" : "stg"
  end

  def env_key_path
    Rails.env.production? ? "production" : "staging"
  end
end
