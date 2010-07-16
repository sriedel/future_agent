class FutureAgent
  class ChildDied < Exception; end

  @agents = {}

  def self.setup_signal_handler
    @old_handler = Signal.trap( "SIGCLD" ) { |signo| child_handler( signo ) }
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
      read_result
    ensure
      @read_pipe.close
    end
  end

  protected
  def self.child_handler( signal_number )
    # since signals can get lost of too many are triggered in too short a time,
    # we will have to loop over Process.wait until no more children can be
    # reaped, i.e. Errno::ECHILD is raised
    loop do

      begin
        exited_child_pid = Process.wait
        handle_pid( signal_number, exited_child_pid )

      rescue Errno::ECHILD
        break
      end

    end
  end

  def self.handle_pid( signal_number, pid )
    unless @agents.has_key?( pid )
      call_original_child_handler signal_number
      return
    end

    agent = @agents.delete(pid)
    agent.result if( $?.success? )
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

  def read_result
    begin
      @result = Marshal.load( @read_pipe.read )
    rescue ArgumentError
      # the write pipe closed without writing any data; this means the
      # other side died somewhere
      @result = nil
      raise FutureAgent::ChildDied
    end
  end

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
      #TODO: How do we handle fatal errors/exceptions for the child?
      #      Some debug logging would be nice... Push this task to the
      #      user of this class for now
      exit( -1 )
    else
      Marshal.dump( result, @write_pipe )
    ensure
      @write_pipe.close
    end
  end
end
