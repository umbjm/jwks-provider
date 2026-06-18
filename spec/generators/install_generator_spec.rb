# frozen_string_literal: true

require "spec_helper"
require "rails/generators"
require "fileutils"
require "tmpdir"

require_relative "../../lib/generators/jwks_provider/install/install_generator"
require_relative "../../lib/generators/jwks_provider/keys/keys_generator"

RSpec.describe JwksProvider::Generators::InstallGenerator do
  let(:tmpdir) { Dir.mktmpdir }

  let(:generator) do
    g = JwksProvider::Generators::InstallGenerator.new([], { app_name: "my-app" }, destination_root: tmpdir)
    g.set_app_name
    g
  end

  before do
    FileUtils.mkdir_p(File.join(tmpdir, "config"))
    File.write(File.join(tmpdir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
  end

  after { FileUtils.rm_rf(tmpdir) }

  describe "#copy_concern" do
    before { generator.copy_concern }

    it "creates json_web_key.rb in app/controllers/concerns/" do
      expect(File).to exist(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
    end

    it "includes the JsonWebKey module" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).to include("module JsonWebKey")
    end

    it "includes sig_key_set method" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).to include("def sig_key_set")
    end

    it "includes signing_key method" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).to include("def signing_key")
    end

    it "includes encryption_key method" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).to include("def encryption_key")
    end

    it "does not contain raw ERB tags in the output" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).not_to include("<%=")
    end

    it "interpolates app_name into kid_sig_key" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).to include("alias/my-app-id-token-")
    end

    it "includes kid_sig_key referencing signing-key-kms-asymmetric-key" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).to include("signing-key-kms-asymmetric-key")
    end

    it "includes kid_enc_key referencing encryption-key-kms-asymmetric-key" do
      content = File.read(File.join(tmpdir, "app/controllers/concerns/json_web_key.rb"))
      expect(content).to include("encryption-key-kms-asymmetric-key")
    end
  end

  describe "#copy_controller" do
    before { generator.copy_controller }

    it "creates jwks_controller.rb in app/controllers/" do
      expect(File).to exist(File.join(tmpdir, "app/controllers/jwks_controller.rb"))
    end

    it "includes JsonWebKey concern" do
      content = File.read(File.join(tmpdir, "app/controllers/jwks_controller.rb"))
      expect(content).to include("include JsonWebKey")
    end

    it "renders sig_key_set as JSON" do
      content = File.read(File.join(tmpdir, "app/controllers/jwks_controller.rb"))
      expect(content).to include("render json: sig_key_set")
    end

    it "defines JwksController" do
      content = File.read(File.join(tmpdir, "app/controllers/jwks_controller.rb"))
      expect(content).to include("class JwksController")
    end
  end

  describe "#set_app_name" do
    it "raises Thor::Error when app_name is blank" do
      g = JwksProvider::Generators::InstallGenerator.new([], { app_name: "" }, destination_root: tmpdir)
      expect { g.set_app_name }.to raise_error(Thor::Error, /app_name cannot be blank/)
    end
  end

  describe "#inject_routes" do
    before { generator.inject_routes }

    it "injects the .well-known/jwks route" do
      content = File.read(File.join(tmpdir, "config/routes.rb"))
      expect(content).to include(".well-known/jwks")
    end

    it "routes to jwks#index" do
      content = File.read(File.join(tmpdir, "config/routes.rb"))
      expect(content).to include("jwks#index")
    end
  end
end
