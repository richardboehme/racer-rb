require "json"
require "vernier"

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

          data = JSON.parse(data)
          # data = data.split(",")
          # File.write("messages", "#{data}\n\n", mode: "a+")
          method_name, return_type, method_owner_name, method_owner_type, constant_path_size, *rest = data

          # Split rest to constants and params based on constant path size
          fragment_name = nil
          path =
            constant_path_size.times.map do |i|
              fragment_name =
                if fragment_name.nil?
                  rest.shift
                else
                  fragment_name = "#{fragment_name}::#{rest.shift}"
                end
              fragment_type = Racer::Trace::Constant::TYPES.fetch(rest.shift)

              Racer::Trace::Constant::PathFragment.new(name: fragment_name, type: fragment_type)
            end

          @queue.push(
            Racer::Trace.new(
              method_owner:
                Racer::Trace::Constant.new(
                  name: method_owner_name,
                  type: Racer::Trace::Constant::TYPES.fetch(method_owner_type),
                  path:
                ),
              method_name:,
              return_type:,
              params: rest.each_slice(3).map { build_param(*it) }
            )
          )
        end
      end
    end
  end

  def build_param(name, class_name, type)
    type =
      Racer::Trace::Param::TYPES.fetch(type.to_i) do |key|
        warn "Unexpected return type received #{key}"
        Racer::Trace::Param::TYPES.first
      end

    Racer::Trace::Param.new(name: name.to_sym, class_name:, type:)
  end
end
