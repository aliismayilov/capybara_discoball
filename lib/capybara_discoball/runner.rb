require 'capybara'
require 'capybara/server'

module Capybara
  module Discoball
    class Runner
      def initialize(server_factory, &block)
        @server_factory = server_factory
        @after_server = block
      end

      def boot
        with_webrick_runner do
          @server = Capybara::Server.new(@server_factory.new)
          @server.boot
        end

        @after_server.call(@server)
      end

      private

      def with_webrick_runner(&block)
        retry_count = 3

        begin
          launch_webrick(&block)
        rescue Errno::EADDRINUSE => e
          raise if retry_count <= 0

          retry_count -= 1
          puts e.inspect
          retry
        end
      end

      def launch_webrick
        default_server_process = Capybara.server
        Capybara.server do |app, port|
          require 'rack/handler/webrick'
          Rack::Handler::WEBrick.run(app, Port: port, AccessLog: [], Logger: WEBrick::Log::new(nil, 0))
        end
        yield
      ensure
        Capybara.server(&default_server_process)
      end
    end
  end
end
