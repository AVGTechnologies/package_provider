require 'package_provider/app/endpoints/base'
require 'sidekiq/api'

module PackageProvider
  class App
    module Endpoints
      # handles uptime endpoint
      class Uptime < Base
        get '/uptime' do
          { uptime: PackageProvider.start_time,
            packer_queue: packer_queue_status,
            repository_queue: repository_queue_status,
            sidekiq_queues: sidekiq_queues_status
          }.to_json
        end

        private

        def packer_queue_status
          { size: Sidekiq::Queue.new('package_packer').size,
            latency: Sidekiq::Queue.new('package_packer').latency
          }
        end

        def repository_queue_status
          { size: Sidekiq::Queue.new('clone_repository').size,
            latency: Sidekiq::Queue.new('clone_repository').latency
          }
        end

        def sidekiq_queues_status
          { RetrySet: Sidekiq::RetrySet.new.size,
            ScheduledSet: Sidekiq::ScheduledSet.new.size
          }
        end
      end
    end
  end
end
