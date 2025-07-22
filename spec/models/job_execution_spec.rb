require 'rails_helper'

RSpec.describe JobExecution, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      job_execution = JobExecution.new(
        job_id: "test-123",
        job_type: "TestJob",
        executed_at: Time.current,
        status: "completed"
      )
      expect(job_execution).to be_valid
    end

    it 'requires job_id' do
      job_execution = JobExecution.new(
        job_type: "TestJob",
        executed_at: Time.current,
        status: "completed"
      )
      expect(job_execution).not_to be_valid
      expect(job_execution.errors[:job_id]).to include("can't be blank")
    end

    it 'requires job_type' do
      job_execution = JobExecution.new(
        job_id: "test-123",
        executed_at: Time.current,
        status: "completed"
      )
      expect(job_execution).not_to be_valid
      expect(job_execution.errors[:job_type]).to include("can't be blank")
    end

    it 'requires unique job_id for the same job_type' do
      JobExecution.create!(job_id: 'test-123', job_type: 'TestJob', executed_at: Time.current, status: 'completed')
      duplicate = JobExecution.new(job_id: 'test-123', job_type: 'TestJob', executed_at: Time.current, status: 'completed')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:job_id]).to include("has already been taken")
    end

    it 'allows same job_id for different job_types' do
      JobExecution.create!(job_id: 'test-123', job_type: 'TestJobA', executed_at: Time.current, status: 'completed')
      different_type = JobExecution.new(job_id: 'test-123', job_type: 'TestJobB', executed_at: Time.current, status: 'completed')
      expect(different_type).to be_valid
    end
  end

  describe '.job_executed?' do
    it 'returns true if job was completed' do
      JobExecution.create!(job_id: 'test-123', job_type: 'TestJob', executed_at: Time.current, status: 'completed')
      expect(JobExecution.job_executed?('test-123', 'TestJob')).to be true
    end

    it 'returns false if job failed' do
      JobExecution.create!(job_id: 'test-123', job_type: 'TestJob', executed_at: Time.current, status: 'failed')
      expect(JobExecution.job_executed?('test-123', 'TestJob')).to be false
    end

    it 'returns false if job does not exist' do
      expect(JobExecution.job_executed?('nonexistent', 'TestJob')).to be false
    end
  end

  describe '.record_execution' do
    it 'records a successful execution' do
      expect {
        JobExecution.record_execution('test-123', 'TestJob', status: 'completed')
      }.to change { JobExecution.count }.by(1)

      execution = JobExecution.last
      expect(execution.job_id).to eq('test-123')
      expect(execution.job_type).to eq('TestJob')
      expect(execution.status).to eq('completed')
      expect(execution.executed_at).to be_present
    end
  end

  describe '#resource_data' do
    it 'parses JSON resource_snapshot' do
      data = { villages_processed: 2, buildings: ['farm', 'woodcutter'] }
      job_execution = JobExecution.new(resource_snapshot: data.to_json)
      expect(job_execution.resource_data).to eq(data.stringify_keys)
    end

    it 'returns empty hash for blank resource_snapshot' do
      job_execution = JobExecution.new(resource_snapshot: nil)
      expect(job_execution.resource_data).to eq({})
    end

    it 'returns empty hash for invalid JSON' do
      job_execution = JobExecution.new(resource_snapshot: 'invalid json')
      expect(job_execution.resource_data).to eq({})
    end
  end
end
