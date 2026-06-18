# frozen_string_literal: true

RSpec.describe JwksProvider do
  it "has a version number" do
    expect(JwksProvider::VERSION).not_to be_nil
  end

  it "version is a valid semver string" do
    expect(JwksProvider::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
