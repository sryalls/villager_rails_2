require 'rails_helper'

RSpec.describe ApplicationService, type: :service do
  # Create a test service to verify the base functionality
  class TestService < ApplicationService
    def initialize(value)
      @value = value
    end

    def call
      if @value == "success"
        success_result("Test successful", { value: @value })
      else
        failure_result("Test failed", { value: @value })
      end
    end
  end

  describe ".call" do
    it "can be called as a class method" do
      result = TestService.call("success")

      expect(result.success).to be true
      expect(result.message).to eq("Test successful")
      expect(result.data[:value]).to eq("success")
    end
  end

  describe "#success_result" do
    it "returns a successful OpenStruct" do
      result = TestService.new("success").call

      expect(result).to be_a(OpenStruct)
      expect(result.success).to be true
      expect(result.message).to eq("Test successful")
      expect(result.data).to be_a(Hash)
    end
  end

  describe "#failure_result" do
    it "returns a failed OpenStruct" do
      result = TestService.new("failure").call

      expect(result).to be_a(OpenStruct)
      expect(result.success).to be false
      expect(result.message).to eq("Test failed")
      expect(result.data).to be_a(Hash)
    end
  end
end
