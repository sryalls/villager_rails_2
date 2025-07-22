require "ostruct"

class ApplicationService
  # Class method to call the service
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private

  # Standard success result structure
  def success_result(message, data = {})
    ::OpenStruct.new(
      success: true,
      message: message,
      data: data
    )
  end

  # Standard failure result structure
  def failure_result(message, data = {})
    ::OpenStruct.new(
      success: false,
      message: message,
      data: data
    )
  end
end
