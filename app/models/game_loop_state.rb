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
  def self.cleanup_old_loops!(keep_duration = 24.hours)
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
end
