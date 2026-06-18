# frozen_string_literal: true

require "spec_helper"
require "openssl"
require "tmpdir"
require "jwt"

RSpec.describe "JsonWebKey concern" do
  let(:tmpdir) { Dir.mktmpdir }
  let(:sig_key)  { OpenSSL::PKey::EC.generate("prime256v1") }
  let(:enc_key)  { OpenSSL::PKey::EC.generate("prime256v1") }

  let(:concern_class) do
    sig_pem = sig_key.to_pem
    enc_pem = enc_key.to_pem
    dir     = tmpdir

    klass = Class.new do
      def initialize(env, root)
        @env  = env
        @root = Pathname.new(root)
      end

      def env_key_path
        @env == "production" ? "production" : "staging"
      end

      def signing_key
        OpenSSL::PKey.read @root.join("config/keys", env_key_path, "sig_key.pem").read
      end

      def encryption_key
        OpenSSL::PKey.read @root.join("config/keys", env_key_path, "enc_key.pem").read
      end

      def sig_key_set
        {
          keys: [
            JWT::JWK.new(signing_key, kid: kid_sig_key, use: "sig", alg: "ES256").export,
            JWT::JWK.new(encryption_key, kid: kid_enc_key, use: "enc", alg: "ECDH-ES+A128KW").export
          ]
        }
      end

      private

      def kid_sig_key
        "alias/my-app-id-token-#{kid_alias}-signing-key-kms-asymmetric-key"
      end

      def kid_enc_key
        "alias/my-app-id-token-#{kid_alias}-encryption-key-kms-asymmetric-key"
      end

      def kid_alias
        @env == "production" ? "prd" : "stg"
      end
    end

    klass
  end

  before do
    %w[staging production].each do |env|
      dir = File.join(tmpdir, "config", "keys", env)
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "sig_key.pem"), sig_key.to_pem)
      File.write(File.join(dir, "enc_key.pem"), enc_key.to_pem)
    end
  end

  after { FileUtils.rm_rf(tmpdir) }

  describe "#kid_alias" do
    it "returns 'prd' for production" do
      obj = concern_class.new("production", tmpdir)
      expect(obj.send(:kid_alias)).to eq("prd")
    end

    it "returns 'stg' for non-production" do
      obj = concern_class.new("staging", tmpdir)
      expect(obj.send(:kid_alias)).to eq("stg")
    end
  end

  describe "#env_key_path" do
    it "returns 'production' for production" do
      obj = concern_class.new("production", tmpdir)
      expect(obj.env_key_path).to eq("production")
    end

    it "returns 'staging' for non-production" do
      obj = concern_class.new("staging", tmpdir)
      expect(obj.env_key_path).to eq("staging")
    end
  end

  describe "#signing_key" do
    it "returns an OpenSSL::PKey instance" do
      obj = concern_class.new("staging", tmpdir)
      expect(obj.signing_key).to be_a(OpenSSL::PKey::PKey)
    end
  end

  describe "#encryption_key" do
    it "returns an OpenSSL::PKey instance" do
      obj = concern_class.new("staging", tmpdir)
      expect(obj.encryption_key).to be_a(OpenSSL::PKey::PKey)
    end
  end

  describe "#sig_key_set" do
    subject(:key_set) { concern_class.new("staging", tmpdir).sig_key_set }

    it "returns a hash with a :keys array" do
      expect(key_set).to have_key(:keys)
      expect(key_set[:keys]).to be_an(Array)
    end

    it "includes two keys" do
      expect(key_set[:keys].length).to eq(2)
    end

    it "first key has use: sig and alg: ES256" do
      sig = key_set[:keys].first
      expect(sig[:use]).to eq("sig")
      expect(sig[:alg]).to eq("ES256")
    end

    it "second key has use: enc and alg: ECDH-ES+A128KW" do
      enc = key_set[:keys].last
      expect(enc[:use]).to eq("enc")
      expect(enc[:alg]).to eq("ECDH-ES+A128KW")
    end

    it "embeds the correct kid for staging signing key" do
      sig = key_set[:keys].first
      expect(sig[:kid]).to eq("alias/my-app-id-token-stg-signing-key-kms-asymmetric-key")
    end

    it "embeds the correct kid for staging encryption key" do
      enc = key_set[:keys].last
      expect(enc[:kid]).to eq("alias/my-app-id-token-stg-encryption-key-kms-asymmetric-key")
    end
  end
end
