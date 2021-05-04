require_relative 'test_base'

class RackDispatchingTest < TestBase

  def self.id58_prefix
    'FF0'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 500
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '166',
  'dispatch has 500 status when no space left on device' do
    externals.instance_exec {
      # See docker-compose.yml
      # See scripts/containers_up.sh create_space_limited_volume()
      @disk = Disk.new(nil, 'one_k')
    }
    dirname = '166'
    filename = '166/file'
    content = 'x'*1024
    disk.assert(command:dir_make_command(dirname))
    disk.assert(command:file_create_command(filename, content))
    message = "No space left on device @ io_write - /one_k/#{filename}"
    body = { "command": file_append_command(filename, content*16) }
    assert_post_raises('run', body, 500, message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '167',
  'dispatch has 500 status when assert_all raises' do
    message = 'commands[1] != true'
    dirname = '167'
    body = { "commands":[
      dir_make_command(dirname),
      dir_make_command(dirname) # repeat
    ]}.to_json
    assert_post_raises('assert_all', body, 500, message)
    disk.assert(command:dir_exists_command(dirname))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

=begin
  test 'F1A',
  'dispatch has 500 status when implementation raises' do
    def prober.sha
      raise ArgumentError, 'wibble'
    end
    assert_get_raises('sha', {}.to_json, 500, 'wibble')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'F1B',
  'dispatch has 500 status when implementation has syntax error' do
    def prober.sha
      raise SyntaxError, 'fubar'
    end
    assert_get_raises('sha', {}.to_json, 500, 'fubar')
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 400
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  #test 'E2A',
  #'dispatch has 400 when method name is unknown' do
  #  assert_post_raises('xyz',
  #    {}.to_json,
  #    400,
  #    'unknown path')
  #end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E2B',
  'dispatch has 400 status when body is not JSON' do
    assert_post_raises('run',
      'xxx',
      400,
      'body is not JSON')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E2C',
  'dispatch has 400 status when body is not JSON Hash' do
    assert_post_raises('run',
      [].to_json,
      400,
      'body is not JSON Hash')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AC6',
  'dispatch has 400 status when commands is missing' do
    assert_post_raises('run_all',
      '{}',
      400,
      'missing:commands:'
    )
  end

  test 'AC7',
  'dispatch has 400 status when commands are malformed' do
    [
      ['{"commands":42}', 'malformed:commands:!Array (Integer):'],
      ['{"commands":[42]}', 'malformed:commands[0]:!Array (Integer):'],
      ['{"commands":[[true]]}', 'malformed:commands[0][0]:!String (TrueClass):'],
      ['{"commands":[["xxx"]]}', 'malformed:commands[0]:Unknown (xxx):'],
      ['{"commands":[["file_read",1,2,3]]}', 'malformed:commands[0]:file_read!3:'],
      ['{"commands":[["file_read",2.9]]}', 'malformed:commands[0]:file_read(filename!=String):']
    ].each do |json, error_message|
      assert_post_raises('run_all', json, 400, error_message)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AC8',
  'dispatch has 400 status when command is missing' do
    assert_post_raises('assert',
      '{}',
      400,
      'missing:command:'
    )
  end

  test 'AC9',
  'dispatch has 400 status when command is malformed' do
    [
      ['{"command":42}', 'malformed:command:!Array (Integer):'],
      ['{"command":[true]}', 'malformed:command[0]:!String (TrueClass):'],
      ['{"command":["xxx"]}', 'malformed:command:Unknown (xxx):'],
      ['{"command":["file_read",1,2,3]}', 'malformed:command:file_read!3:'],
      ['{"command":["file_read",2.9]}', 'malformed:command:file_read(filename!=String):']
    ].each do |json, error_message|
      assert_post_raises('assert', json, 400, error_message)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 200 probes
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

=begin
  test 'E39',
  'dispatches to alive' do
    def prober.alive?
      'hello from alive?'
    end
    assert_dispatch('alive', {}.to_json, 'hello from alive?')
  end

  test 'E40',
  'dispatches to ready' do
    def prober.ready?
      'hello from ready?'
    end
    assert_dispatch('ready', {}.to_json, 'hello from ready?')
  end

  test 'E41',
  'dispatches to sha' do
    def prober.sha
      'hello from sha'
    end
    assert_dispatch('sha', {}.to_json, 'hello from sha')
  end
=end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # 200 batches
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E48',
  'dispatches to assert_all' do
    disk_stub('assert_all')
    assert_dispatch('assert_all',
      { commands: well_formed_commands }.to_json,
      'hello from stubbed disk.assert_all'
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E51',
  'dispatches to assert' do
    disk_stub('assert')
    assert_dispatch('assert',
      { command: well_formed_command }.to_json,
      'hello from stubbed disk.assert'
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E52',
  'dispatches to run' do
    disk_stub('run')
    assert_dispatch('run',
      { command: well_formed_command }.to_json,
      'hello from stubbed disk.run'
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E47',
  'dispatches to run_all' do
    disk_stub('run_all')
    assert_dispatch('run_all',
      { commands: well_formed_commands }.to_json,
      'hello from stubbed disk.run_all'
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E49',
  'dispatches to run_until_true' do
    disk_stub('run_until_true')
    assert_dispatch('run_until_true',
      { commands: well_formed_commands }.to_json,
      'hello from stubbed disk.run_until_true'
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E50',
  'dispatches to run_until_false' do
    disk_stub('run_until_false')
    assert_dispatch('run_until_false',
      { commands: well_formed_commands }.to_json,
      'hello from stubbed disk.run_until_false'
    )
  end

  private

  def disk_stub(name)
    disk.define_singleton_method(name) do |*_args|
      "hello from stubbed disk.#{name}"
    end
  end

  # - - - - - - -

  def well_formed_command
    [ 'dir_make',  '/cyber-dojo/katas/12/34/45' ]
  end

  def well_formed_commands
    [
      [ 'dir_make',    '/cyber-dojo/katas/12/34/45' ],
      [ 'dir_exists?', '/cyber-dojo/katas/12/34/45' ],
      [ 'file_create', '/cyber-dojo/katas/12/34/45/manifest.json', {"a"=>[1,2,3]}.to_json ],
    ]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_dispatch(name, args, stubbed)
    if query?(name)
      qname = name + '?'
    else
      qname = name
    end
    assert_rack_call(name, args, { qname => stubbed })
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def query?(name)
    %w( alive ready exists group_exists kata_exists ).include?(name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def XXX_assert_dispatch_raises(name, args, status, message)
    response,stderr = with_captured_stderr { rack_call(name, args) }
    assert_equal status, response[0], "message:#{message},stderr:#{stderr}"
    assert_equal({ 'Content-Type' => 'application/json' }, response[1])
    assert_exception(response[2][0], name, args, message)
    assert_exception(stderr,         name, args, message)
  end

  def assert_post_raises(name, body, expected_status, expected_message)
    response,stdout,stderr = with_captured_ss {
      json_post '/'+name, body
    }
    assert_equal '', stdout, :stdout_is_empty
    refute_equal '', stderr, :stderr_is_not_empty

    actual_type = response.headers["Content-Type"]
    actual_status = response.status
    actual_body = response.body

    assert_equal 'application/json', actual_type, :type
    assert_equal expected_status, actual_status, :status

    assert_exception(response.body, name, expected_message)
    assert_exception(stderr,        name, expected_message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_exception(s, name, message)
    json = JSON.parse!(s)
    exception = json['exception']
    refute_nil exception
    assert_equal '/'+name, exception['path'], "path:#{__LINE__}"
    assert_equal 'SaverService', exception['class'], "exception['class']:#{__LINE__}"
    assert_equal message, exception['message'], "exception['message']:#{__LINE__}"
    assert_equal 'Array', exception['backtrace'].class.name, "exception['backtrace'].class.name:#{__LINE__}"
    assert_equal 'String', exception['backtrace'][0].class.name, "exception['backtrace'][0].class.name:#{__LINE__}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_rack_call(name, args, expected)
    response = rack_call(name, args)
    assert_equal 200, response[0]
    assert_equal({ 'Content-Type' => 'application/json' }, response[1])
    assert_equal [to_json(expected)], response[2], args
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def rack_call(name, args)
    rack = RackDispatcher.new(externals, RackRequestStub)
    env = { path_info:name, body:args }
    rack.call(env)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def to_json(body)
    JSON.generate(body)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def with_captured_ss
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new('', 'w')
    $stderr = StringIO.new('', 'w')
    response = yield
    return [ response, $stderr.string, $stdout.string ]
  ensure
    $stderr = old_stderr
    $stdout = old_stdout
  end

end