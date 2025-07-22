class PlayLoopJob < ApplicationJob
  queue_as :default

  def perform(job_id: nil)
    result = PlayLoopService.call(job_id: job_id)
    handle_service_result(result, context: "Play loop job")
  end
end
