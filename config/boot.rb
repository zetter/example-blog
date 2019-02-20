ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'csv'

class RailsTracer
  SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

  def initialize
    @threads = Hash.new
    if defined? Thread.main
      @threads[Thread.main.object_id] = 0
    else
      @threads[Thread.current.object_id] = 0
    end
    @get_line_procs = {}
  end

  def get_thread_no
    if no = @threads[Thread.current.object_id]
      no
    else
      @threads[Thread.current.object_id] = @threads.size
    end
  end

  def get_line(file, line)
    if p = @get_line_procs[file]
      return p.call(line)
    end

    unless list = SCRIPT_LINES__[file]
      list = File.readlines(file) rescue []
      SCRIPT_LINES__[file] = list
    end

    if l = list[line - 1]
      l
    else
      "-\n"
    end
  end

  def trace(tp)
    begin
      puts  [get_thread_no, tp.lineno, tp.path, tp.defined_class.to_s, tp.binding.try(:receiver).try(:class).try(:to_s), tp.method_id, tp.event, get_line(tp.path, tp.lineno)].to_csv
    rescue => e
      puts e.inspect
      puts 'ERROR!!!'
    end
  end
end

tracer = RailsTracer.new
trace = TracePoint.trace do |tp|
  tracer.trace(tp) if Time.now.min == 26
end


require 'bundler/setup' # Set up gems listed in the Gemfile.
