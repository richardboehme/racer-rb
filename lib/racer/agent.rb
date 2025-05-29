require "json"

class Racer::Agent
  def initialize(server_path, collectors)
    @queue = Queue.new
    @server_path = server_path
    @server = nil
    @collectors = collectors
    @should_stop = false
    @agent_threads = []
  end

  def start
    unless @server.nil?
      raise "tried to start server again"
    end
    Process.setproctitle("Racer: Agent")

    @server = UNIXServer.new(@server_path)

    worker_thread =
      Thread.new do
        while (trace = @queue.pop) do
          @collectors.each do |collector|
            collector.collect(trace)
          end
        end

        @collectors.each do |collector|
          collector.stop
        end
      end

    trap "HUP" do
      exit
    end

    at_exit do
      puts "Shutting down agent. Waiting for all clients to finish sending messages..."
      @agent_threads.each(&:join)
      puts "Closed server. Waiting for collectors to process messages..."
      @server.close
      @queue.close if @queue.empty?
      File.unlink(@server_path)
      worker_thread.join
      puts "Done"
    end

    main_loop
  end

  private

  def main_loop
    loop do
      connection = @server.accept
      # this is not really good because new clients need to wait until first client finished but for now its okay
      @agent_threads <<
        Thread.new do
          worker_loop(connection)
        end
    end
  end

  def worker_loop(connection)
    pending_message = nil
    loop do
      # TODO: Difference between connection.read connection.recv and connection.recvmsg
      received_message = connection.read(1024)
      # TODO: Is this an error? I would expect it waits until there is something to read?
      if received_message.nil?
        # warn "received nil as message"
        next
      end

      # File.write("messages", "#{received_message}\n\n", mode: "a+")

      *messages, last_message = received_message.split("\0")

      if pending_message
        if messages.empty?
          last_message = "#{pending_message}#{last_message}"
        else
          first_message = messages.shift
          messages.prepend(*("#{pending_message}#{first_message}".split("\0")))
        end

        pending_message = nil
      end

      if received_message.end_with?("\0")
        messages << last_message
      else
        pending_message = last_message
      end

      messages.each do |data|
        if data == "stop"
          puts "Received last message from one worker"
          # Exits the thread
          return
        end

        data = JSON.parse(data)
        # File.write("parsed_messages", "#{data}\n\n", mode: "a+")

        method_name = data.shift
        method_kind =
          Racer::Trace::KINDS.fetch(data.shift) do |index|
            warn "Unexpected method kind received #{index}"
            Racer::Trace::KINDS.first
          end

        method_visibility =
          Racer::Trace::VISIBILITIES.fetch(data.shift) do |index|
            warn "Unexpected method visibility received #{index}"
            Racer::Trace::VISIBILITIES.first
          end

        return_type = shift_constant_instance(data)
        method_owner = shift_constant_instance(data)
        method_callee =
          if data.first
            shift_constant_instance(data)
          else
            # pop nil from data
            data.shift
          end

        constant_updates = shift_constant_updates(data)

        params, block_param = shift_params(data)


        unless data.empty?
          warn "Received more data then expected: #{data}"
        end

        @queue.push(
          Racer::Trace.new(
            method_owner:,
            method_callee:,
            method_name:,
            method_kind:,
            method_visibility:,
            return_type:,
            params:,
            block_param:,
            constant_updates:
          )
        )
      end
    end
  end

  def shift_block_trace(data)
    self_type = shift_constant_instance(data)
    return_type = shift_constant_instance(data)
    params, block_param = shift_params(data)

    Racer::Trace::BlockTrace.new(self_type:, return_type:, params:, block_param:)
  end

  def shift_params(data)
    params_size = data.shift
    params = params_size.times.map { shift_param(data) }

    block_present = data.shift
    block_param =
      if block_present
        block_name = data.shift
        traces_count = data.shift
        traces = traces_count.times.map { shift_block_trace(data) }

        Racer::Trace::BlockParam.new(
          name: block_name,
          traces:
        )
      end

    [params, block_param]
  end

  def shift_param(data)
    name = data.shift
    type = Racer::Trace::Param::TYPES.fetch(data.shift) do |key|
      warn "Unexpected return type received #{key}"
      Racer::Trace::Param::TYPES.first
    end

    type_name = shift_constant_instance(data)

    Racer::Trace::Param.new(name: name&.to_sym, type_name:, type:)
  end

  def shift_constant_updates(data)
    constant_update_count = data.shift
    constant_update_count.times.map do
      shift_constant(data)
    end
  end

  def shift_constant(data)
    name = data.shift
    anonymous = data.shift
    type = data.shift

    superclass = data.shift

    included_modules_count = data.shift
    included_modules = included_modules_count.times.map { data.shift }

    prepended_modules_count = data.shift
    prepended_modules = prepended_modules_count.times.map { data.shift }

    extended_modules_count = data.shift
    extended_modules = extended_modules_count.times.map { data.shift }

    Racer::Trace::Constant.new(
      name:,
      anonymous:,
      type: Racer::Trace::Constant::TYPES.fetch(type),
      superclass:,
      included_modules:,
      prepended_modules:,
      extended_modules:
    )
  end

  def shift_constant_instance(data)
    name = data.shift
    singleton = data.shift
    generic_argument_count = data.shift

    generic_arguments =
      generic_argument_count.times.map do
        union_size = data.shift

        union_size.times.map do
          shift_constant_instance(data)
        end
      end

    Racer::Trace::ConstantInstance.new(
      name:,
      singleton:,
      generic_arguments:
    )
  end
end
