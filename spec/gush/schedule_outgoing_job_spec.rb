# frozen_string_literal: true

require 'spec_helper'

describe Gush::ScheduleOutgoingJob do
  subject { described_class.new }

  let!(:workflow)   { TestWorkflow.create }
  let!(:job)        { client.find_job(workflow.id, 'Prepare') }
  let(:config)      { Gush.configuration.to_json }
  let!(:client)     { Gush::Client.new }

  describe '#perform' do
    context 'when job completes succesfully' do
      before do
        job.finish!
        client.persist_job(workflow.id, job)
      end
      it 'marks outgoing jobs enqueued' do
        subject.perform(workflow.id, 'Prepare')
        expect(client.find_job(workflow.id, 'FetchFirstJob')).to be_enqueued
        expect(client.find_job(workflow.id, 'FetchSecondJob')).to be_enqueued
        expect(client.find_job(workflow.id, 'PersistFirstJob')).not_to be_enqueued
      end
    end

    context 'when job failed to enqueue outgoing jobs' do
      before do
        allow(RedisMutex).to receive(:with_lock).and_raise(RedisMutex::LockError)
      end

      it 'enqueues outgoing jobs in SingleEnqueue Worker' do
        expect(Gush::SingleEnqueue).to receive(:perform_later).with(workflow.id, job.name)
        subject.perform(workflow.id, 'Prepare')
      end
    end
  end
end
