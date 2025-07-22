class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  # Handle service result with consistent logging and error handling
  # This makes it easy to plug in error reporting tools later
  def handle_service_result(result, context: nil)
    context_info = context ? " (#{context})" : ""

    if result.success
      Rails.logger.info "Successfully completed#{context_info}: #{result.message}"
      # Future: Add success metrics/monitoring here
    else
      Rails.logger.error "Job failed#{context_info}: #{result.message}"
      # Future: Add error reporting (Sentry, Rollbar, etc.) here
      raise StandardError, result.message
    end
  end
end
