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
    it "creates enc_key and sig_key PEM files for stg and prd" do
      run_keys_generator(tmpdir)

      %w[stg prd].each do |env|
        expect(File).to exist(File.join(tmpdir, "config/keys/enc_key_#{env}.pem"))
        expect(File).to exist(File.join(tmpdir, "config/keys/sig_key_#{env}.pem"))
      end
    end

    it "generates valid EC PEM content in enc_key PEM files" do
      run_keys_generator(tmpdir)

      %w[stg prd].each do |env|
        pem = File.read(File.join(tmpdir, "config/keys/enc_key_#{env}.pem"))
        expect { OpenSSL::PKey::EC.new(pem) }.not_to raise_error
      end
    end

    it "skips generation if enc_key_stg.pem already exists" do
      dir = File.join(tmpdir, "config/keys")
      FileUtils.mkdir_p(dir)
      existing_key = OpenSSL::PKey::EC.generate("prime256v1").to_pem
      File.write(File.join(dir, "enc_key_stg.pem"), existing_key)

      run_keys_generator(tmpdir)

      expect(File.read(File.join(dir, "enc_key_stg.pem"))).to eq(existing_key)
    end

    it "generates a prime256v1 EC key" do
      run_keys_generator(tmpdir)

      pem = File.read(File.join(tmpdir, "config/keys/enc_key_stg.pem"))
      key = OpenSSL::PKey::EC.new(pem)
      expect(key.group.curve_name).to eq("prime256v1")
    end
  end
end
