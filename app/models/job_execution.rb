class JobExecution < ApplicationRecord
  belongs_to :village, optional: true
  belongs_to :building, optional: true

  validates :job_id, presence: true, uniqueness: { scope: :job_type }
  validates :job_type, presence: true
  validates :executed_at, presence: true
  validates :status, inclusion: { in: %w[completed failed] }

  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :for_village, ->(village_id) { where(village_id: village_id) }
  scope :for_building, ->(building_id) { where(building_id: building_id) }
  scope :recent, -> { where('executed_at >= ?', 1.hour.ago) }

  def self.job_executed?(job_id, job_type)
    exists?(job_id: job_id, job_type: job_type, status: 'completed')
  end

  def self.record_execution(job_id, job_type, **options)
    create!(
      job_id: job_id,
      job_type: job_type,
      executed_at: Time.current,
      **options
    )
  end

  def resource_data
    return {} if resource_snapshot.blank?
    JSON.parse(resource_snapshot)
  rescue JSON::ParserError
    {}
  end

  def resource_data=(data)
    self.resource_snapshot = data.to_json
  end
end
