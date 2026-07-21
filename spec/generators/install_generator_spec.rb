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

  describe "#create_initializer" do
    before { generator.create_initializer }

    it "creates jwks_provider.rb in config/initializers/" do
      expect(File).to exist(File.join(tmpdir, "config/initializers/jwks_provider.rb"))
    end

    it "sets JwksProvider.app_name" do
      content = File.read(File.join(tmpdir, "config/initializers/jwks_provider.rb"))
      expect(content).to include("JwksProvider.app_name = \"my-app\"")
    end
  end

  describe "#copy_controller" do
    before { generator.copy_controller }

    it "creates jwks_controller.rb in app/controllers/" do
      expect(File).to exist(File.join(tmpdir, "app/controllers/jwks_controller.rb"))
    end

    it "includes JwksProvider::JsonWebKey concern" do
      content = File.read(File.join(tmpdir, "app/controllers/jwks_controller.rb"))
      expect(content).to include("include JwksProvider::JsonWebKey")
    end

    it "renders keys_set as JSON" do
      content = File.read(File.join(tmpdir, "app/controllers/jwks_controller.rb"))
      expect(content).to include("render json: keys_set")
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
