# frozen_string_literal: true

require "spec_helper"
require "openssl"
require "tmpdir"
require "jwt"
require "jwks_provider/json_web_key"

RSpec.describe "JsonWebKey concern" do
  let(:tmpdir) { Dir.mktmpdir }
  let(:sig_key)  { OpenSSL::PKey::EC.generate("prime256v1") }
  let(:enc_key)  { OpenSSL::PKey::EC.generate("prime256v1") }

  let(:concern_class) do
    sig_key.to_pem
    enc_key.to_pem
    tmpdir

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

    context "when testing base64 encoding/decoding preserves newlines" do
      let(:test_key) { OpenSSL::PKey::EC.generate("prime256v1") }
      let(:pem_content) { test_key.to_pem }

      it "base64 encoded string does not contain newlines" do
        # Use strict_encode64 which does not add newlines
        base64_encoded = Base64.strict_encode64(pem_content)

        # The encoded string should not contain \n characters
        expect(base64_encoded).not_to include("\n")
      end

      it "preserves original bytes including newlines after base64 decode" do
        # Encode the PEM content to base64
        base64_encoded = Base64.strict_encode64(pem_content)

        # Decode it back
        decoded_content = Base64.strict_decode64(base64_encoded)

        # The decoded content should match the original exactly
        expect(decoded_content).to eq(pem_content)
      end

      it "can load the key after base64 encode/decode cycle" do
        # Simulate storing in environment variable as base64
        base64_encoded = Base64.strict_encode64(pem_content)
        decoded_content = Base64.strict_decode64(base64_encoded)

        # Should be able to load the key successfully
        loaded_key = OpenSSL::PKey.read(decoded_content)
        expect(loaded_key).to be_a(OpenSSL::PKey::EC)
        expect(loaded_key.to_pem).to eq(pem_content)
      end

      it "handles PEM with proper line breaks after base64 decode" do
        # PEM files have specific line breaks (64 chars per line)
        # Base64 encoding should preserve these
        base64_encoded = Base64.strict_encode64(pem_content)
        decoded_content = Base64.strict_decode64(base64_encoded)

        # Check that the decoded content has proper PEM structure
        expect(decoded_content).to start_with("-----BEGIN")
        expect(decoded_content.strip).to end_with("-----END EC PRIVATE KEY-----")
        expect(decoded_content).to include("\n")

        # Should be parseable by OpenSSL
        expect { OpenSSL::PKey.read(decoded_content) }.not_to raise_error
      end
    end

    context "when testing the actual module implementation" do
      let(:test_key) { OpenSSL::PKey::EC.generate("prime256v1") }
      let(:pem_content) { test_key.to_pem }
      let(:base64_encoded) { Base64.strict_encode64(pem_content) }

      before do
        # Stub ENV and Rails
        allow(ENV).to receive(:[]).with("ENC_KEY").and_return(base64_encoded)
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("staging"))
      end

      it "decodes base64 and loads the key successfully" do
        # Create a class that includes the actual concern
        klass = Class.new do
          include JwksProvider::JsonWebKey

          def self.app_name
            "my-app"
          end
        end

        obj = klass.new
        loaded_key = obj.encryption_key

        expect(loaded_key).to be_a(OpenSSL::PKey::EC)
        expect(loaded_key.to_pem).to eq(pem_content)
      end

      it "raises error when ENC_KEY is not set" do
        allow(ENV).to receive(:[]).with("ENC_KEY").and_return(nil)

        klass = Class.new do
          include JwksProvider::JsonWebKey

          def self.app_name
            "my-app"
          end
        end

        obj = klass.new
        expect { obj.encryption_key }.to raise_error("ENC_KEY environment variable is not set")
      end

      it "raises error when ENC_KEY is not valid base64" do
        allow(ENV).to receive(:[]).with("ENC_KEY").and_return("not-valid-base64!!!")

        klass = Class.new do
          include JwksProvider::JsonWebKey

          def self.app_name
            "my-app"
          end
        end

        obj = klass.new
        expect { obj.encryption_key }.to raise_error("ENC_KEY must be a valid base64-encoded string")
      end
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
