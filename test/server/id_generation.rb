require_relative 'test_base'
require_relative 'saver_fake'
require_source 'model/id_generator'
#require_source 'model'
require 'fileutils'
require 'tmpdir'

class IdGenerationTest < TestBase

  def self.hex_prefix
    'A6D'
  end

  def hex_setup
    externals.instance_exec {
      @saver = SaverFake.new(self)
    }
  end

  # - - - - - - - - - - - - - - - - - - -

  test '062', %w(
  alphabet has 58 characters
  ) do
    assert_equal 58, alphabet.size
  end

  # - - - - - - - - - - - - - - - - - - -

  test '063', %w(
  entire alphabet is used in group ids
  ) do
    id_generator = IdGenerator.new(externals)
    counts = {}
    until counts.size === 58 do
      id_generator.group_id.each_char do |ch|
        counts[ch] = true
      end
    end
    assert_equal alphabet.chars.sort, counts.keys.sort
  end

  # - - - - - - - - - - - - - - - - - - -

  test '064', %w(
  entire alphabet is used in kata ids
  ) do
    id_generator = IdGenerator.new(externals)
    counts = {}
    until counts.size === 58 do
      id_generator.kata_id.each_char do |ch|
        counts[ch] = true
      end
    end
    assert_equal alphabet.chars.sort, counts.keys.sort
  end

  # - - - - - - - - - - - - - - - - - - -

  test '065', %w(
  every letter of the alphabet can be used as part of a dir-name
  ) do
    diagnostic = 'forward slash is the dir separator'
    refute alphabet.include?('/'), diagnostic
    diagnostic = 'dot is a dir navigator'
    refute alphabet.include?('.'), diagnostic
    diagnostic = 'single quote to protect all other letters'
    refute alphabet.include?("'"), diagnostic
    alphabet.each_char do |letter|
      path = Dir.mktmpdir("/tmp/#{letter}")
      FileUtils.mkdir_p(path)
      at_exit { FileUtils.remove_entry(path) }
    end
  end

  # - - - - - - - - - - - - - - - - - - -

  test '13d', %w(
  id 999999 is reserved for a kata id when saver is offline
  ) do
    id = 'eF762A'
    id_generator = stubbed_id_generator(saver_offline_id+id)
    assert_equal id, id_generator.kata_id
  end

  # - - - - - - - - - - - - - - - - - - -

  test '14a', %w(
  kata-id generator will skip id that already exists as a group
  ) do
    group_id = 'chy6BJ'
    saver.assert(command:saver.dir_make_command(group_id_path(group_id)))
    id = 'x67WpA'
    id_generator = stubbed_id_generator(group_id + id)
    assert_equal id, id_generator.kata_id
  end

  # - - - - - - - - - - - - - - - - - - -

  test '14b', %w(
  group-id generator will skip id that already exists as a kata
  ) do
    kata_id = '5rTJv5'
    saver.assert(command:saver.dir_make_command(kata_id_path(kata_id)))
    id = 'hY86s3'
    id_generator = stubbed_id_generator(kata_id + id)
    assert_equal id, id_generator.group_id
  end

  # - - - - - - - - - - - - - - - - - - -

  test '068', %w(
  id?(s) true examples
  ) do
    assert id?('012AaE')
    assert id?('345BbC')
    assert id?('678HhJ')
    assert id?('999PpQ')
    assert id?('263VvW')
  end

  # - - - - - - - - - - - - - - - - - - -

  test '069', %w(
  id?(s) false examples
  ) do
    refute id?(42),  :integer_not_string
    refute id?(nil), :nil_not_string
    refute id?({}),  :hash_not_string
    refute id?([]),  :array_not_string
    refute id?('I'), :India_not_in_alphabet
    refute id?('i'), :india_not_in_alphabet
    refute id?('O'), :Oscar_not_in_alphabet
    refute id?('o'), :oscar_not_in_alphabet
    refute id?('12345'), :not_length_6
    refute id?('1234567'), :not_length_6
  end

  # - - - - - - - - - - - - - - - - - - -

  test '13e', %w(
  kata-id generation tries 42 times and then gives up and returns nil
  and you either have the worst random-number generator ever
  or you are the unluckiest person ever
  or both
  ) do
    id_generator = stubbed_id_generator(saver_offline_id*42)
    assert_nil id_generator.kata_id
  end

  # - - - - - - - - - - - - - - - - - - -

  test '13f', %w(
  group-id generation tries 42 times and then gives up and returns nil
  and you either have the worst random-number generator ever
  or you are the unluckiest person ever
  or both
  ) do
    id_generator = stubbed_id_generator(saver_offline_id*42)
    assert_nil id_generator.group_id
  end

  # - - - - - - - - - - - - - - - - - - -

=begin

  test '13b', %w(
  group-id does not exist before generation, does after
  ) do
    id =  'sD92wM'
    refute group_exists?(id), "group_exists?(#{id}) !!"
    id_generator = stubbed_id_generator(id)
    assert_equal id, id_generator.group_id
    assert group_exists?(id), "!group_exists?(#{id}) !!"
  end

  # - - - - - - - - - - - - - - - - - - -

  test '13c', %w(
  kata-id does not exist before generation, does after
  ) do
    id =  '7w3RPx'
    refute kata_exists?(id), "kata_exists?(#{id}) !!"
    id_generator = stubbed_id_generator(id)
    assert_equal id, id_generator.kata_id
    assert kata_exists?(id), "!kata_exists?(#{id}) !!"
  end

=end

  private

  include IdPather

  def id?(s)
    IdGenerator::id?(s)
  end

  def alphabet
    IdGenerator::ALPHABET
  end

  def saver_offline_id
    IdGenerator::SAVER_OFFLINE_ID
  end

  def stubbed_id_generator(stub)
    externals.instance_exec {
      @random = RandomStub.new(stub)
    }
    IdGenerator.new(externals)
  end

  class RandomStub
    def initialize(letters)
      alphabet = IdGenerator::ALPHABET
      @indexes = letters.each_char.map{ |ch| alphabet.index(ch) }
      @n = 0
    end
    def sample(_size)
      index = @indexes[@n]
      @n += 1
      index
    end
  end

end
