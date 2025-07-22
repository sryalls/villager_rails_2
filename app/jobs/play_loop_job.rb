class PlayLoopJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Play loop executed at #{Time.current}"

    result = PlayLoopService.call(*args)
    handle_service_result(result, context: "Play loop")
  end
end
