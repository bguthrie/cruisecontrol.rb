require 'ftools'
require 'fileutils'
require 'test/unit/assertions'

class Sandbox
  include Test::Unit::Assertions
  attr_reader :root

  def self.debug
    sandbox = Sandbox.new
    yield sandbox
  end

  def self.create
    sandbox = Sandbox.new
    original_error = nil

    begin
      Dir.chdir(sandbox.root) { yield sandbox }
    rescue => e
      original_error = e
      raise
    ensure
      begin
        sandbox.clean_up
      rescue
        if original_error 
          STDERR.puts "ALERT: a test raised an error and failed to release some lock(s) in the sandbox directory"
          raise(original_error)
        else 
          raise
        end
      end
    end
  end

  def initialize
    @root = File.expand_path("__sandbox")
    clean_up
    FileUtils.mkdir_p @root
  end

  # usage new :file=>'my file.rb', :with_contents=>'some stuff'
  def new(options)
    name = File.join(@root, options[:file])
    dir = File.dirname(name)
    FileUtils.mkdir_p dir

    if (binary_content = options[:with_binary_content] || options[:with_binary_contents])
      File.open(name, "wb") {|f| f << binary_content }
    else
      File.open(name, "w") {|f| f << (options[:with_content] || options[:with_contents] || '')}
    end
  end

  # usage assert :file=>'my file.rb', :has_contents=>'some stuff'
  def assert(options)
    name = File.join(@root, options[:file])
    if (expected_content = options[:has_content] || options[:has_contents])
      assert_equal(expected_content, File.read(name))
    else
      fail('expected something to assert')
    end
  end

  def clean_up
    FileUtils.rm_rf @root
    if File.exists? @root
      raise "Could not remove directory #{@root.inspect}, something is probably still holding a lock on it" 
    end
  end

  module Helper
    def in_sandbox(&block)
      Sandbox.create do |sandbox|
        @dir = File.expand_path(sandbox.root)
        @stdout = "#{@dir}/stdout"
        @stderr = "#{@dir}/stderr"
        @prompt = "#{@dir} #{Platform.user}$"
        yield(sandbox)
      end
    end
    
    def with_sandbox_project(&block)
      in_sandbox do |sandbox|
        project = Project.new('my_project', nil, '.')
        project.path = sandbox.root
        yield(sandbox, project)
      end
    end
    
  end

end