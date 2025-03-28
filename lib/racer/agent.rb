
class Racer::Agent
  def initialize(server_path)
    @queue = Queue.new
    @server_path = server_path
    @server = nil
  end

  def start
    unless @server.nil?
      raise "tried to start server again"
    end

    @server = UNIXServer.new(@server_path)

    worker_thread =
      Thread.new do
        # collector = Racer::Collectors::RBSCollector.new
        # while (trace = @queue.pop) do
        #   collector.collect(trace)
        # end
        # collector.stop
      end

    main_loop

    @server.close
    File.unlink(@server_path)
    worker_thread.join
  end

  private

  def main_loop
    pending_message = nil
    loop do
      connection = @server.accept
      # this is not really good because new clients need to wait until first client finished but for now its okay
      loop do
        received_message = connection.read(1024)
        *messages, last_message = received_message.split("\n")

        if pending_message
          messages[0] = "#{pending_message}#{messages[0]}"
          pending_message = nil
        end

        if received_message.end_with?("\n")
          messages << last_message
        else
          pending_message = last_message
        end


        messages.each do |data|
          if data == "stop"
            @queue.close
            return
          end

          data = data.split(",")
          method_owner, method_owner_type, *params = data

          @queue.push(
            Racer::Trace.new(
              method_owner:,
              method_owner_type:,
              params: params.each_slice(2).to_a
            )
          )
        end
      end
    end
  end
end
