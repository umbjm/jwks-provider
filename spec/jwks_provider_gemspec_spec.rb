# frozen_string_literal: true

require "spec_helper"

RSpec.describe "jwks-provider.gemspec" do
  subject(:gemspec) do
    Gem::Specification.load(File.expand_path("../jwks-provider.gemspec", __dir__))
  end

  let(:runtime_dependency_names) do
    gemspec.dependencies.select { |dep| dep.type == :runtime }.map(&:name)
  end

  it "depends on the jwt gem" do
    expect(runtime_dependency_names).to include("jwt")
  end

  it "depends on the jose gem" do
    expect(runtime_dependency_names).to include("jose")
  end

  it "requires jwt version ~> 3.2" do
    dep = gemspec.dependencies.find { |d| d.name == "jwt" }
    expect(dep.requirement.to_s).to eq("~> 3.2")
  end

  it "requires jose version ~> 1.2" do
    dep = gemspec.dependencies.find { |d| d.name == "jose" }
    expect(dep.requirement.to_s).to eq("~> 1.2")
  end
end
