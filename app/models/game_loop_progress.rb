class GameLoopProgress < ApplicationRecord
  belongs_to :village, optional: true
  belongs_to :building, optional: true
  
  validates :loop_cycle_id, presence: true
  validates :progress_type, presence: true
  validates :completed_at, presence: true
  
  # Record that a village has been queued for processing in this cycle
  def self.mark_village_queued!(loop_cycle_id, village)
    find_or_create_by!(
      loop_cycle_id: loop_cycle_id,
      progress_type: 'village_queued',
      village: village
    ) do |record|
      record.completed_at = Time.current
    end
  end
  
  # Record that a building has been processed in this cycle
  def self.mark_building_processed!(loop_cycle_id, village, building)
    find_or_create_by!(
      loop_cycle_id: loop_cycle_id,
      progress_type: 'building_processed',
      village: village,
      building: building
    ) do |record|
      record.completed_at = Time.current
    end
  end
  
  # Get villages that have already been queued in this cycle
  def self.queued_villages_for_cycle(loop_cycle_id)
    where(loop_cycle_id: loop_cycle_id, progress_type: 'village_queued')
      .includes(:village)
      .map(&:village)
  end
  
  # Get buildings that have already been processed for a village in this cycle
  def self.processed_buildings_for_village_cycle(loop_cycle_id, village)
    where(
      loop_cycle_id: loop_cycle_id, 
      progress_type: 'building_processed',
      village: village
    ).includes(:building).map(&:building)
  end
  
  # Cleanup old progress records (keep only recent cycles)
  def self.cleanup_old_progress!(keep_cycles = 10)
    # Get the 10 most recent cycle IDs
    recent_cycles = select(:loop_cycle_id)
      .distinct
      .order(created_at: :desc)
      .limit(keep_cycles)
      .pluck(:loop_cycle_id)
    
    where.not(loop_cycle_id: recent_cycles).delete_all
  end
end
