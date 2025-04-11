
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

    at_exit do
      File.unlink(@server_path)
    end

    @server = UNIXServer.new(@server_path)

    worker_thread =
      Thread.new do
        collector = Racer::Collectors::RBSCollector.new
        while (trace = @queue.pop) do
          collector.collect(trace)
        end
        collector.stop
        puts "Stopped collecting"
      end

    main_loop

    @server.close
    worker_thread.join
  end

  private

  def main_loop
    pending_message = nil
    loop do
      connection = @server.accept
      # this is not really good because new clients need to wait until first client finished but for now its okay
      loop do
        # TODO: Difference between connection.read connection.recv and connection.recvmsg
        received_message = connection.read(1024)
        # TODO: Is this an error? I would expect it waits until there is something to read?
        next if received_message.nil?

        # File.write("messages", "#{received_message}\n\n", mode: "a+")

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
            puts "Received last message from worker"
            @queue.close
            return
          end

          data = data.split(",")
          method_owner, method_owner_type, method_name, return_type, *params = data

          @queue.push(
            Racer::Trace.new(
              method_owner:,
              method_owner_type:,
              method_name:,
              return_type:,
              params: params.each_slice(3).map { build_param(*it, data) }
            )
          )
        end
      end
    end
  end

  def build_param(name, class_name, type, message)
    type =
      Racer::Trace::Param::TYPES.fetch(type.to_i) do |key|
        warn "Unexpected return type received #{key}, message: #{message}"
        Racer::Trace::Param::TYPES.first
      end

    Racer::Trace::Param.new(name: name.to_sym, class_name:, type:)
  end
end
