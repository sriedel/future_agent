class FutureAgent
  class ChildDied < Exception; end

  @agents = {}

  def self.setup_signal_handler
    @old_handler = Signal.trap( "SIGCLD" ) { |signo| child_handler( signo ) }
  end

  def self.child_handler( signal_number )
    # since signals can get lost of too many are triggered in too short a time,
    # we will have to loop over Process.wait until no more children can be
    # reaped, i.e. Errno::ECHILD is raised
    loop do
      begin
        exited_child_pid = Process.wait

        unless @agents.has_key?( exited_child_pid )
          call_original_child_handler signal_number
          return
        end

        agent = @agents.delete(exited_child_pid)

        if( $?.success? )
          agent.result
        end
      rescue Errno::ECHILD
        break
      end
    end
  end

  def self.call_original_child_handler( signal_number )
    return unless @old_handler

    case @old_handler
      when String, Symbol
        #TODO: deal with handlers in classes
        Kernel.send @old_handler, signal_number

      when Proc
        @old_handler.call( signal_number )
    end
  end
  setup_signal_handler


  def self.fork( &block )
    agent = new( &block )
    child_pid = agent.send :fork!
    @agents[child_pid] = agent
    agent
  end

  def initialize( &block )
    @async_block = block
  end

  # parent method
  def result
    return @result if defined?( @result )

    begin
      @result = Marshal.load( @read_pipe.read )
    rescue ArgumentError
      # the write pipe closed without writing any data; this means the
      # other side died somewhere
      @result = nil
      raise FutureAgent::ChildDied
    ensure
      @read_pipe.close
    end
  end

  protected
  def fork!
    @read_pipe, @write_pipe = IO.pipe
    retval = fork

    if( retval ) # parent
      @write_pipe.close
      return retval

    else         # child
      @read_pipe.close
      process_block
      exit
    end
  end

  def process_block # child method
    begin
      result = @async_block.call
    rescue Exception
      STDERR.puts "Exception caught; exiting with -1"
      exit( -1 )
    else
      Marshal.dump( result, @write_pipe )
    ensure
      @write_pipe.close
    end
  end
end
