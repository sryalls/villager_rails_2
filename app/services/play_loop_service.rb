class PlayLoopService
  def call(*args)
    Rails.logger.info "Play loop service started at #{Time.current}"

    Village.all.each do |village|
      VillageLoopJob.perform_later(village.id)
    end

    Rails.logger.info "Play loop service completed at #{Time.current}"
  end
end
