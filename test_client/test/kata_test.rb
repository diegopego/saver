require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix
    '975'
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # exists?()
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '392',
  'exists?(id) is true with id returned from successful create()' do
    id = kata.create(starter.manifest)
    assert kata.exists?(id)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # create(), manifest()
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '42D',
  'manifest() raises when id does not exist' do
    id = 'A4AB37'
    assert_service_error("id:invalid:#{id}") {
      kata.manifest(id)
    }
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '421',
  'create() manifest() round-trip' do
    id = kata.create(starter.manifest)
    manifest = starter.manifest
    manifest['id'] = id
    if v_test?(2)
      manifest['version'] = 2
    end
    assert_equal manifest, kata.manifest(id)
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '42B', %w(
  create() an individual practice-session
  results in a manifest that does not contain entries
  for group or index
  ) do
    id = kata.create(starter.manifest)
    manifest = kata.manifest(id)
    assert_nil manifest['group']
    assert_nil manifest['index']
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # ran_tests(), events(), event()
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '821',
  'events(id) raises when id does not exist' do
    id = 'A4AB37'
    assert_service_error("id:invalid:#{id}") {
      kata.events(id)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '822',
  'event(id,n) raises when n does not exist' do
    id = kata.create(starter.manifest)
    assert_service_error('index:invalid:1') {
      kata.event(id, 1)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '722',
  'event(id) raises when id does exist' do
    id = '653c8C'
    assert_service_error("id:invalid:#{id}") {
      kata.event(id, -1)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '823',
  'ran_tests(id,index,...) raises when id or index does not exist' do
    id = 'A4AB37'
    if v_test?(2)
      message = 'index:invalid:1'
    else
      message = "id:invalid:#{id}"
    end
    assert_service_error(message) {
      kata.ran_tests(*make_ran_test_args(id, 1, edited_files))
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '824', %w(
  ran_tests(id,index,...) raises when index is -1
  because -1 can only be used on event()
  ) do
    id = kata.create(starter.manifest)
    assert_service_error('index:invalid:-1') {
      kata.ran_tests(*make_ran_test_args(id, -1, edited_files))
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '825', %w(
  ran_tests(id,index,...) raises when index is 0
  because 0 is used for create()
  ) do
    id = kata.create(starter.manifest)
    assert_service_error('index:invalid:0') {
      kata.ran_tests(*make_ran_test_args(id, 0, edited_files))
    }
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '826', %w(
  ran_tests(id,index,...) raises when index already exists
  and does not add a new event,
  in other words it fails atomically ) do
    id = kata.create(starter.manifest)
    expected_events = [event0]
    assert_equal expected_events, kata.events(id)

    kata.ran_tests(*make_ran_test_args(id, 1, edited_files))
    event = {
      'colour' => red,
      'time' => time_now,
      'duration' => duration
    }
    if v_test?(2)
      event['index'] = 1
    end
    expected_events << event
    assert_equal expected_events, kata.events(id)

    assert_service_error('index:invalid:1') {
      kata.ran_tests(*make_ran_test_args(id, 1, edited_files))
    }

    assert_equal expected_events, kata.events(id)
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '827', %w(
  ran_tests() does NOT raise when index-1 does not exist
  and the reason for this is partly speed
  and partly robustness against temporary saver outage ) do
    id = kata.create(starter.manifest)
    kata.ran_tests(*make_ran_test_args(id, 1, edited_files))
    # ran.tests(*make_ran_test_args(id, 2, ...)) assume save failed
    kata.ran_tests(*make_ran_test_args(id, 3, edited_files)) # <====
  end

  # - - - - - - - - - - - - - - - - - - - - -

  v_test [0,1,2], '829',
  'after ran_tests() there is one more event' do
    id = kata.create(starter.manifest)

    expected_events = [event0]
    diagnostic = '#0 events(id)'
    assert_equal expected_events, kata.events(id), diagnostic

    files = starter.manifest['visible_files']
    expected = { 'files' => files }

    assert_equal expected, kata.event(id, 0), 'event(id,0)'
    assert_equal expected, kata.event(id, -1), 'event(id,-1)'

    kata.ran_tests(*make_ran_test_args(id, 1, edited_files))

    event = {
      'colour' => red,
      'time' => time_now,
      'duration' => duration
    }
    if v_test?(2)
      event['index'] = 1
    end
    expected_events << event
    diagnostic = '#1 events(id)'
    assert_equal expected_events, kata.events(id), diagnostic

    expected = rag_event(edited_files, stdout, stderr, status)
    assert_equal expected, kata.event(id, 1), 'event(id,1)'
    assert_equal expected, kata.event(id, -1), 'event(id,-1)'
  end

  private

  def rag_event(files, stdout, stderr, status)
    {
      'files' => files,
      'stdout' => stdout,
      'stderr' => stderr,
      'status' => status
    }
  end

end
