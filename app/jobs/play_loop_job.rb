class PlayLoopJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Extract job_id if provided, otherwise generate one
    job_id = args.last.is_a?(String) && args.last.start_with?('play-loop-') ? args.pop : "play-loop-#{Time.current.to_i}"
    
    Rails.logger.info "Play loop executed at #{Time.current} (Job ID: #{job_id})"

    result = PlayLoopService.call(*args, job_id: job_id)
    handle_service_result(result, context: "Play loop, Job ID: #{job_id}")
  end
end
