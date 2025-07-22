class GameLoopState < ApplicationRecord
  validates :loop_type, presence: true
  validates :started_at, presence: true
  validates :status, inclusion: { in: %w[running completed failed] }

  # Ensure only one active loop per type/identifier
  validates :status, uniqueness: {
    scope: [ :loop_type, :identifier ],
    conditions: -> { where(status: "running") },
    message: "Only one active loop allowed per type and identifier"
  }

  scope :running, -> { where(status: "running") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :for_type, ->(type) { where(loop_type: type) }
  scope :recent, ->(time_window = 1.hour) { where(started_at: time_window.ago..Time.current) }

  # Progress tracking - serialize as JSON
  serialize :processed_villages, type: Array, coder: JSON
  serialize :processed_buildings, type: Hash, coder: JSON

  # Initialize progress tracking on creation
  after_initialize :initialize_progress_tracking

  # Check if a loop can start (no other loop of same type running)
  def self.can_start_loop?(loop_type, identifier = nil)
    !running.for_type(loop_type).where(identifier: identifier).exists?
  end

  # Start a new loop (atomic operation)
  def self.start_loop!(loop_type, identifier = nil, sidekiq_job_id = nil)
    transaction do
      # Double-check no running loop exists
      if running.for_type(loop_type).where(identifier: identifier).exists?
        raise ActiveRecord::RecordInvalid, "Loop already running for #{loop_type}/#{identifier}"
      end

      create!(
        loop_type: loop_type,
        identifier: identifier,
        started_at: Time.current,
        status: "running",
        sidekiq_job_id: sidekiq_job_id
      )
    end
  end

  # Complete a loop
  def complete!
    update!(status: "completed", completed_at: Time.current)
  end

  # Fail a loop
  def fail!(error_message = nil)
    update!(status: "failed", completed_at: Time.current, error_message: error_message)
  end

  # Get the current running loop (if any)
  def self.current_running_loop(loop_type, identifier = nil)
    running.for_type(loop_type).where(identifier: identifier).first
  end

  # Cleanup old completed/failed loops (keep recent ones for debugging)
  def self.cleanup_old_loops!(keep_duration = nil)
    keep_duration ||= Rails.application.config.game_loop_cleanup_keep_duration || 24.hours
    where(status: [ "completed", "failed" ])
      .where("completed_at < ?", keep_duration.ago)
      .delete_all
  end

  def duration
    return nil unless completed_at
    completed_at - started_at
  end

  def running?
    status == "running"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  # Progress tracking methods

  # Record that a village has been queued for processing in this loop
  def mark_village_queued!(village)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    self.processed_villages ||= []
    unless self.processed_villages.include?(village_id)
      self.processed_villages << village_id
      save!
    end
  end

  # Record that a building has been processed for a village in this loop
  def mark_building_processed!(village, building)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    building_id = building.is_a?(Building) ? building.id : building.to_i
    
    self.processed_buildings ||= {}
    self.processed_buildings[village_id.to_s] ||= []
    
    unless self.processed_buildings[village_id.to_s].include?(building_id)
      self.processed_buildings[village_id.to_s] << building_id
      save!
    end
  end

  # Get villages that have already been queued in this loop
  def queued_villages
    return Village.none if processed_villages.blank?
    Village.where(id: processed_villages)
  end

  # Get buildings that have been processed for a specific village in this loop
  def processed_buildings_for_village(village)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    building_ids = processed_buildings&.dig(village_id.to_s) || []
    return Building.none if building_ids.empty?
    Building.where(id: building_ids)
  end

  # Check if a village has been queued in this loop
  def village_queued?(village)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    processed_villages&.include?(village_id) || false
  end

  # Check if a building has been processed for a village in this loop
  def building_processed?(village, building)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    building_id = building.is_a?(Building) ? building.id : building.to_i
    processed_buildings&.dig(village_id.to_s)&.include?(building_id) || false
  end

  private

  def initialize_progress_tracking
    self.processed_villages ||= []
    self.processed_buildings ||= {}
  end
end
