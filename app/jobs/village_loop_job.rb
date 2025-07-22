class VillageLoopJob < ApplicationJob
  queue_as :default

  def perform(village_id, loop_cycle_id: nil)
    result = VillageLoopService.call(village_id, loop_cycle_id: loop_cycle_id, job_id: job_id)
    handle_service_result(result, context: "Village loop job for Village ID: #{village_id}")
  end
end
