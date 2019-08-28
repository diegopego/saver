require_relative 'test_base'

class GroupTest < TestBase

  def self.hex_prefix
    '974'
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # group_exists?()
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  old_new_test '392',
  'group_exists? is true after creation' do
    id = group.create(starter.manifest)
    assert group.exists?(id)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # group_create(), group_manifest()
  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  old_new_test '420',
  'group_manifest() raises when id does not exist' do
    id = 'A4AB37'
    assert_service_error("id:invalid:#{id}") {
      group.manifest(id)
    }
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test '42E',
  'group_create() group_manifest() round-trip' do
    id = group.create(starter.manifest)
    manifest = starter.manifest
    manifest['id'] = id
    assert_equal manifest, group.manifest(id)
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  test '42F',
  '[new] extremely unlikely race-condition in group_create()' do
    # 1) get an unused group-id, use it in a manifest
    # 2) attempt to create group using manifest
    # 3) between 1 and 2 unused group-id is used 
    gid = group.create(starter.manifest)
    externals.instance_exec {
      @group_id_generator = Class.new do
        def initialize(id); @id = id; end
        def id; @id; end
      end.new(gid)
    }
    assert_service_error("id:invalid:#{gid}") {
      group.create(starter.manifest)
    }
  end

  #- - - - - - - - - - - - - - - - - - - - - -
  # group_join() / group_joined()
  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test '1D0',
  'group_join raises when id does not exist' do
    id = 'A4AB37'
    assert_service_error("id:invalid:#{id}") {
      group.join(id, indexes)
    }
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test '1D3', %w(
  group_join a non-full group with valid id succeeds
  and returns the kata's id
  and the manifest of the joined participant contains
  the group id and the avatar index ) do
    gid = group.create(starter.manifest)
    shuffled = indexes
    kid = group.join(gid, shuffled)
    assert kata.exists?(kid)
    manifest = kata.manifest(kid)
    assert_equal gid, manifest['group_id']
    assert_equal shuffled[0], manifest['group_index']
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test '1D4', %w(
  group_join with a valid id succeeds 64 times
  then its full and it fails with nil
  ) do
    gid = group.create(starter.manifest)
    kids = []
    avatar_indexes = []
    64.times do
      kid = group.join(gid, indexes)
      refute_nil kid
      assert kid.is_a?(String), "kid is a #{kid.class.name}!"
      assert_equal 6, kid.size
      assert kata.exists?(kid), "!kata_exists?(#{kid})"
      kids << kid
      assert_equal kids.sort, group.joined(gid).sort

      index = kata.manifest(kid)['group_index']
      refute_nil index
      assert index.is_a?(Integer), "index is a #{index.class.name}"
      assert (0..63).include?(index), "!(0..63).include?(#{index})"
      refute avatar_indexes.include?(index), "avatar_indexes.include?(#{index})!"
      avatar_indexes << index
    end
    refute_equal (0..63).to_a, avatar_indexes
    assert_equal (0..63).to_a, avatar_indexes.sort
    assert_nil group.join(gid, indexes)
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test '1D2',
  'group_joined returns nil when the id does not exist' do
    assert_nil group.joined('A4aB37')
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test '1D5',
  'group_joined information can be retrieved' do
    gid = group.create(starter.manifest)
    kids = group.joined(gid)
    expected = []
    assert_equal(expected, kids, 'someone has already joined!')
    (1..4).to_a.each do |n|
      kid = group.join(gid, indexes)
      expected << kid
      kids = group.joined(gid)
      assert kids.is_a?(Array), "kids is a #{kids.class.name}!"
      assert_equal n, kids.size, 'incorrect size!'
      assert_equal expected.sort, kids.sort, 'does not round-trip!'
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - -
  # group_events
  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test 'A04', %w(
  group_events returns nil when the id does not exist ) do
      assert_nil group.events('A4aB37')
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  old_new_test 'A05', %w(
  group_events is a BatchMethod for web's dashboard ) do
    gid = group.create(starter.manifest)
    kid1 = group.join(gid, indexes)
    index1 = kata.manifest(kid1)['group_index']
    kid2 = group.join(gid, indexes)
    index2 = kata.manifest(kid2)['group_index']
    kata.ran_tests(*make_ran_test_args(kid1, 1, edited_files))

    expected = {
      kid1 => {
        'index' => index1,
        'events' => [event0, { 'colour' => 'red', 'time' => time_now, 'duration' => duration }]
      },
      kid2 => {
        'index' => index2,
        'events' => [event0]
      }
    }
    actual = group.events(gid)
    assert_equal expected, actual
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  test 'A06', %w( test speed of alternative implementations ) do
    one = '{"s":23,"t":[1,2,3,4],"u":"blah"}'
    all = ([one] * 142).join("\n")
    _,slower = timed {
      all.lines.map { |line|
        JSON.parse!(line)
      }
    }
    _,faster = timed {
      JSON.parse!('[' + all.lines.join(',') + ']')
    }
    assert faster < slower, "faster:#{faster}, slower:#{slower}"
  end

  private

  def indexes
    (0..63).to_a.shuffle
  end

  #- - - - - - - - - - - - - - - - - - - - - -

  def timed
    started = Time.now
    result = yield
    finished = Time.now
    duration = '%.4f' % (finished - started)
    [result,duration]
  end

end
