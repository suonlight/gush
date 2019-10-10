module Gush
  class ScheduleOutgoingJob < ::ActiveJob::Base
    def perform(workflow_id, job_name)
      RedisMutex.with_lock("gush_enqueue_outgoing_jobs_#{workflow_id}-#{job_name}", sleep: 0.3, block: 2) do
        out = client.find_job(workflow_id, job_name)
        client.enqueue_job(workflow_id, out) if out.ready_to_start?
      end
    end

    private

    attr_reader :workflow_id, :job_name

    def client
      @client ||= Gush::Client.new(Gush.configuration)
    end
  end
end
