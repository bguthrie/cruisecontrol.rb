require 'test_helper'

class PlatformTest < Test::Unit::TestCase
  include FileSandbox
  
  def test_create_child_process_detaches_to_avoid_zombie_processes
    Kernel.stubs(:respond_to?).with(:fork).returns true
    Platform.expects(:fork).returns(123)
    Process.expects(:detach).with(123)
    
    Platform.create_child_process("project", "command")
  end

  def test_create_child_process_spawns_thread_if_kernel_cannot_fork
    Kernel.stubs(:respond_to?).with(:fork).returns false
    Thread.expects(:new)
    
    Platform.create_child_process("project", "command")

  end
  
end
