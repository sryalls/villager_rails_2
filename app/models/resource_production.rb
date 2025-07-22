class ResourceProduction < ApplicationRecord
  belongs_to :village
  belongs_to :building
  belongs_to :resource

  validates :quantity_produced, presence: true, numericality: { greater_than: 0 }
  validates :building_multiplier, presence: true, numericality: { greater_than: 0 }
  validates :produced_at, presence: true

  scope :recent, ->(time_window = 30.minutes) { where(produced_at: time_window.ago..Time.current) }
  scope :for_village, ->(village_id) { where(village_id: village_id) }
  scope :for_building, ->(building_id) { where(building_id: building_id) }
  scope :for_cycle, ->(cycle_id) { where(loop_cycle_id: cycle_id) }

  # Check if building already produced resources in a specific cycle (preferred method)
  def self.produced_in_cycle?(cycle_id, building, village)
    return false unless cycle_id

    where(village: village, building: building, loop_cycle_id: cycle_id)
      .exists?
  end

  # Legacy time-based check (deprecated - use cycle-based instead)
  def self.recently_produced?(village, building, time_window = nil)
    Rails.logger.warn "WARNING: recently_produced? is deprecated. Use produced_in_cycle? instead."
    time_window ||= Rails.application.config.resource_production_window || 25.seconds

    where(village: village, building: building)
      .where(produced_at: time_window.ago..Time.current)
      .exists?
  end

  # Record production (idempotent within cycle)
  def self.record_production!(village, building, resource, quantity, multiplier = 1, cycle_id = nil)
    # Check if already produced in this cycle
    if cycle_id && produced_in_cycle?(cycle_id, building, village)
      Rails.logger.info "Skipping production for Building #{building.id} - already produced in cycle #{cycle_id}"
      return false
    end

    transaction do
      # Double-check within transaction for cycle-based idempotency
      if cycle_id && produced_in_cycle?(cycle_id, building, village)
        return false
      end

      create!(
        village: village,
        building: building,
        resource: resource,
        quantity_produced: quantity,
        building_multiplier: multiplier,
        produced_at: Time.current,
        loop_cycle_id: cycle_id
      )

      # Update the actual village resource
      village_resource = VillageResource.find_or_create_by!(
        village: village,
        resource: resource
      )
      village_resource.increment!(:count, quantity)

      true
    end
  end

  # Get production summary for a village in time window
  def self.production_summary(village, time_window = 1.hour)
    recent(time_window)
      .for_village(village.id)
      .joins(:resource, :building)
      .group("resources.name", "buildings.name")
      .sum(:quantity_produced)
  end

  # Cleanup old production records (keep recent ones for audit)
  def self.cleanup_old_productions!(keep_duration = nil)
    keep_duration ||= Rails.application.config.resource_production_cleanup_keep_duration || 7.days
    where("produced_at < ?", keep_duration.ago).delete_all
  end
end
