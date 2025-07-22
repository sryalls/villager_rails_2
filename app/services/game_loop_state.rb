class GameLoopState
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Attributes
  attribute :id, :string
  attribute :loop_type, :string
  attribute :identifier, :string
  attribute :status, :string, default: "running"
  attribute :started_at, :datetime
  attribute :completed_at, :datetime
  attribute :error_message, :string
  attribute :sidekiq_job_id, :string
  attribute :processed_villages, :string # JSON array stored as string
  attribute :processed_buildings, :string # JSON hash stored as string

  # Validations
  validates :loop_type, presence: true
  validates :started_at, presence: true
  validates :status, inclusion: { in: %w[running completed failed] }

  # Redis TTL for cache entries (default 2 hours)
  DEFAULT_TTL = 2.hours

  class << self
    # Check if a loop can start (no other loop of same type running)
    def can_start_loop?(loop_type, identifier = nil)
      !current_running_loop(loop_type, identifier)
    end

    # Start a new loop (atomic operation using Redis)
    def start_loop!(loop_type, identifier = nil, sidekiq_job_id = nil)
      cache_key = running_loop_key(loop_type, identifier)

      # Try to acquire lock atomically
      loop_id = SecureRandom.uuid
      state_data = {
        id: loop_id,
        loop_type: loop_type,
        identifier: identifier,
        status: "running",
        started_at: Time.current.iso8601,
        sidekiq_job_id: sidekiq_job_id,
        processed_villages: "[]",
        processed_buildings: "{}"
      }

      # Use Redis SET with NX (only set if not exists) for atomic operation
      success = Rails.cache.write(cache_key, state_data, expires_in: DEFAULT_TTL, unless_exist: true)

      if success
        # Also store by ID for lookups
        Rails.cache.write(state_key(loop_id), state_data, expires_in: DEFAULT_TTL)
        new(state_data)
      else
        raise StandardError, "Loop already running for #{loop_type}/#{identifier}"
      end
    end

    # Get the current running loop (if any)
    def current_running_loop(loop_type, identifier = nil)
      cache_key = running_loop_key(loop_type, identifier)
      state_data = Rails.cache.read(cache_key)
      return nil unless state_data
      new(state_data)
    end

    # Find a loop state by ID
    def find_by(id:)
      return nil unless id
      state_data = Rails.cache.read(state_key(id))
      return nil unless state_data
      new(state_data)
    end

    private

    def running_loop_key(loop_type, identifier = nil)
      "game_loop_state:running:#{loop_type}:#{identifier}"
    end

    def state_key(id)
      "game_loop_state:#{id}"
    end
  end

  # Instance methods

  def initialize(attributes = {})
    super
    # Parse JSON strings if they exist
    @processed_villages_array = processed_villages ? JSON.parse(processed_villages) : []
    @processed_buildings_hash = processed_buildings ? JSON.parse(processed_buildings) : {}
  end

  # Complete a loop
  def complete!
    self.status = "completed"
    self.completed_at = Time.current
    save!
    cleanup_running_cache!
  end

  # Fail a loop
  def fail!(error_message = nil)
    self.status = "failed"
    self.completed_at = Time.current
    self.error_message = error_message
    save!
    cleanup_running_cache!
  end

  # Save state to Redis
  def save!
    return false unless valid?

    state_data = {
      id: id,
      loop_type: loop_type,
      identifier: identifier,
      status: status,
      started_at: started_at&.iso8601,
      completed_at: completed_at&.iso8601,
      error_message: error_message,
      sidekiq_job_id: sidekiq_job_id,
      processed_villages: @processed_villages_array.to_json,
      processed_buildings: @processed_buildings_hash.to_json
    }

    # Update by ID
    Rails.cache.write(self.class.send(:state_key, id), state_data, expires_in: DEFAULT_TTL)

    # Update running cache if still running
    if running?
      running_key = self.class.send(:running_loop_key, loop_type, identifier)
      Rails.cache.write(running_key, state_data, expires_in: DEFAULT_TTL)
    end

    true
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
    unless @processed_villages_array.include?(village_id)
      @processed_villages_array << village_id
      save!
    end
  end

  # Record that a building has been processed for a village in this loop
  def mark_building_processed!(village, building)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    building_id = building.is_a?(Building) ? building.id : building.to_i

    @processed_buildings_hash[village_id.to_s] ||= []

    unless @processed_buildings_hash[village_id.to_s].include?(building_id)
      @processed_buildings_hash[village_id.to_s] << building_id
      save!
    end
  end

  # Get villages that have already been queued in this loop
  def queued_villages
    return Village.none if @processed_villages_array.empty?
    Village.where(id: @processed_villages_array)
  end

  # Get buildings that have been processed for a specific village in this loop
  def processed_buildings_for_village(village)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    building_ids = @processed_buildings_hash[village_id.to_s] || []
    return Building.none if building_ids.empty?
    Building.where(id: building_ids)
  end

  # Check if a village has been queued in this loop
  def village_queued?(village)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    @processed_villages_array.include?(village_id)
  end

  # Check if a building has been processed for a village in this loop
  def building_processed?(village, building)
    village_id = village.is_a?(Village) ? village.id : village.to_i
    building_id = building.is_a?(Building) ? building.id : building.to_i
    @processed_buildings_hash.dig(village_id.to_s)&.include?(building_id) || false
  end

  private

  def cleanup_running_cache!
    # Remove from running cache when completed/failed
    running_key = self.class.send(:running_loop_key, loop_type, identifier)
    Rails.cache.delete(running_key)
  end
end
