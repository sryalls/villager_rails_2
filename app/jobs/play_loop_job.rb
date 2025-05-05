class PlayLoopJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Play loop executed at #{Time.current}"
    PlayLoopService.new.call(*args)
  end
end
