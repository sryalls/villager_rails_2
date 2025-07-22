require 'rails_helper'
require 'ostruct'

RSpec.describe ApplicationJob, type: :job do
  # Create a test job to verify the base functionality
  class TestJob < ApplicationJob
    def perform(should_succeed: true)
      result = if should_succeed
        OpenStruct.new(success: true, message: "Test successful")
      else
        OpenStruct.new(success: false, message: "Test failed")
      end

      handle_service_result(result, context: "Test context")
    end
  end

  describe "#handle_service_result" do
    context "when result is successful" do
      it "does not raise error for successful results" do
        expect {
          TestJob.perform_now(should_succeed: true)
        }.not_to raise_error
      end
    end

    context "when result is failure" do
      it "raises StandardError for failed results" do
        expect {
          TestJob.perform_now(should_succeed: false)
        }.to raise_error(StandardError, "Test failed")
      end
    end

    context "when no context is provided" do
      class SimpleTestJob < ApplicationJob
        def perform(should_succeed: true)
          result = OpenStruct.new(success: should_succeed, message: "Simple test")
          handle_service_result(result)
        end
      end

      it "handles results without context information" do
        expect {
          SimpleTestJob.perform_now(should_succeed: true)
        }.not_to raise_error
      end

      it "still raises errors when result fails" do
        expect {
          SimpleTestJob.perform_now(should_succeed: false)
        }.to raise_error(StandardError, "Simple test")
      end
    end
  end
end
