module Gush
  class SingleEnqueue < Worker
    queue_as :single_enqueue

    def perform(workflow_id, job_id)
      setup_job(workflow_id, job_id)

      enqueue_outgoing_jobs
    end

    def workflow
      @workflow ||= client.find_workflow(workflow_id)
    end
  end
end
