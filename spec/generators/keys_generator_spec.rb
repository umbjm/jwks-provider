# frozen_string_literal: true

require "spec_helper"
require "rails/generators"
require "fileutils"
require "tmpdir"

require_relative "../../lib/generators/jwks_provider/keys/keys_generator"

RSpec.describe JwksProvider::Generators::KeysGenerator do
  let(:tmpdir) { Dir.mktmpdir }

  def run_keys_generator(destination)
    Dir.chdir(destination) do
      generator = JwksProvider::Generators::KeysGenerator.new([], {}, destination_root: destination)
      generator.generate_key_pairs
    end
  end

  after { FileUtils.rm_rf(tmpdir) }

  describe "#generate_key_pairs" do
    it "creates enc_key.pem and sig_key.pem for staging and production" do
      run_keys_generator(tmpdir)

      %w[staging production].each do |env|
        expect(File).to exist(File.join(tmpdir, "config/keys/#{env}/enc_key.pem"))
        expect(File).to exist(File.join(tmpdir, "config/keys/#{env}/sig_key.pem"))
      end
    end

    it "generates valid RSA PEM content in enc_key.pem" do
      run_keys_generator(tmpdir)

      %w[staging production].each do |env|
        pem = File.read(File.join(tmpdir, "config/keys/#{env}/enc_key.pem"))
        expect { OpenSSL::PKey::RSA.new(pem) }.not_to raise_error
      end
    end

    it "skips generation if enc_key.pem already exists" do
      dir = File.join(tmpdir, "config/keys/staging")
      FileUtils.mkdir_p(dir)
      existing_key = OpenSSL::PKey::RSA.generate(2048).to_pem
      File.write(File.join(dir, "enc_key.pem"), existing_key)

      run_keys_generator(tmpdir)

      expect(File.read(File.join(dir, "enc_key.pem"))).to eq(existing_key)
    end

    it "generates a 2048-bit RSA key" do
      run_keys_generator(tmpdir)

      pem = File.read(File.join(tmpdir, "config/keys/staging/enc_key.pem"))
      key = OpenSSL::PKey::RSA.new(pem)
      expect(key.n.num_bits).to eq(2048)
    end
  end
end
