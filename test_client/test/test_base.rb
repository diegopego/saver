require_relative 'hex_mini_test'
require_relative '../src/externals_v0'
require_relative '../src/externals_v1'
require_relative '../src/externals_v2'

class TestBase < HexMiniTest

  def initialize(arg)
    super(arg)
  end

  # - - - - - - - - - - - - - - - - - -

  def self.v_test(versions, hex_suffix, *lines, &block)
    versions.each do |version|
      v = version.to_s
      v_lines = ["<version=#{v}>"] + lines
      test(hex_suffix + v, *v_lines, &block)
    end
  end

  def v_test?(n)
    test_name.start_with?("<version=#{n.to_s}>")
  end

  def externals
    if v_test?(2)
      @externals ||= Externals_v2.new
    elsif v_test?(1)
      @externals ||= Externals_v1.new
    else
      @externals ||= Externals_v0.new
    end
  end

  # - - - - - - - - - - - - - - - - - -

  def assert_service_error(message, &block)
    if v_test?(0)
      error = assert_raises(ServiceError) { block.call }
      json = JSON.parse(error.message)
      assert_equal message, json['message']
    else
      error = assert_raises(ArgumentError) { block.call }
      assert_equal message, error.message
    end
  end

  # - - - - - - - - - - - - - - - - - -

  def saver
    externals.saver
  end

  def group
    externals.group
  end

  def kata
    externals.kata
  end

  def id_generator
    externals.id_generator
  end

  def starter
    externals.starter
  end

  # - - - - - - - - - - - - - - - - - -

  def make_ran_test_args(id, n, files)
    [ id, n, files, time_now, duration, stdout, stderr, status, red ]
  end

  def time_now
    [2016,12,2, 6,14,57,4587]
  end

  def duration
    1.778
  end

  def stdout
    file('')
  end

  def stderr
    file('Assertion failed: answer() == 42')
  end

  def status
    23
  end

  def red
    'red'
  end

  def edited_files
    { 'cyber-dojo.sh' => file('gcc'),
      'hiker.c'       => file('#include "hiker.h"'),
      'hiker.h'       => file('#ifndef HIKER_INCLUDED'),
      'hiker.tests.c' => file('#include <assert.h>')
    }
  end

  def file(content)
    { 'content' => content,
      'truncated' => false
    }
  end

  def event0
    zero = {
      'event'  => 'created',
      'time'   => creation_time
    }
    if v_test?(2)
      zero['index'] = 0
    end
    zero
  end

  def creation_time
    starter.creation_time
  end

end
