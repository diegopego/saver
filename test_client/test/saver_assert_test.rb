
require_relative 'test_base'
require_relative '../src/saver_service'
require_relative 'saver_service_fake'

class SaverAssertTest < TestBase

  def self.hex_prefix
    '94D'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # dir_exists?()

  multi_test '431', %w(
  |dir_exists?(dirname) is true
  |when dirname is a String
  |and dirname exists as a dir
  ) do
    dirname = 'client/N4/f4/31'
    dir_make(dirname)
    assert dir_exists?(dirname)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '432', %w(
  |dir_exists?(dirname) raises and does nothing
  |when dirname does not exist as a dir
  |and dirname does not exist as a file
  ) do
    dirname = 'client/N5/s4/32'
    message = 'command != true'
    assert_raises_SaverException(message,'exists?',dirname ) {
      dir_exists?(dirname)
    }
    refute saver.run(saver.dir_exists_command(dirname)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '433', %w(
  |dir_exists?(dirname) raises and does nothing
  |when dirname exists as a file
  ) do
    dirname = 'client/N5/s4/33'
    filename = dirname + '/' + 'readme.txt'
    content = 'hello world'
    dir_make(dirname)
    file_create(filename, content)
    message = 'command != true'
    assert_raises_SaverException(message,'exists?',filename) {
      dir_exists?(filename)
    }
    assert_equal content, saver.run(saver.file_read_command(filename)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '434', %w(
  |dir_exists?(dirname) raises and does nothing
  |when dirname is not a String
  ) do
    dirname = 42
    message = 'malformed:command:exists?(key!=String):'
    assert_raises_SaverException(message,'exists?',dirname) {
      dir_exists?(dirname)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # dir_make()

  multi_test '568', %w(
  |dir_make(dirname) is true
  |when dirname is a String
  |and dirname does not exist as a dir
  |and dirname does not exist as a file
  ) do
    dirname = 'client/N5/s7/68'
    assert dir_make(dirname)
    assert dir_exists?(dirname)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '569', %w(
  |dir_make(dirname) raises and does nothing
  |when dirname exists as a dir
  ) do
    dirname = 'client/N5/s7/69'
    dir_make(dirname)
    message = 'command != true'
    assert_raises_SaverException(message,'create',dirname) {
      dir_make(dirname)
    }
    assert dir_exists?(dirname), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '570', %w(
  |dir_make(dirname) raises and does nothing
  |when dirname exists as a file
  ) do
    dirname = 'client/N5/s7/70'
    filename = dirname + '/' + 'readme.me'
    content = '#readme'
    dir_make(dirname)
    file_create(filename, content)
    message = 'command != true'
    assert_raises_SaverException(message,'create',filename) {
      dir_make(filename)
    }
    assert_equal content, file_read(filename)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '571', %w(
  |dir_make(dirname) raises
  |when dirname is not a String
  ) do
    dirname = true
    message = 'malformed:command:create(key!=String):'
    assert_raises_SaverException(message,'create',dirname) {
      dir_make(dirname)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # file_create()

  multi_test '2E8', %w(
  |file_create(filename,content) is true
  |when filename is a String naming a dir that exists
  |and filename is a String naming a file that does not exist
  |and content is a String
  ) do
    dirname = 'client/N5/s2/E8'
    filename = dirname + '/events.json'
    content = '{"time":[3,4,5,6,7,8]}'
    dir_make(dirname)
    assert file_create(filename,content)
    assert_equal content, file_read(filename)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '2E9', %w(
  |file_create(filename,content) raises and does nothing
  |when dir of filename does not exist
  ) do
    dirname = 'client/N5/s2/E9'
    filename = dirname + '/events.json'
    content = '{"time":[3,4,5,6,7,8]}'
    # no dir_make(dirname)
    message = 'command != true'
    assert_raises_SaverException(message,'write',filename,content) {
      file_create(filename,content)
    }
    refute saver.run(saver.dir_exists_command(dirname)), :did_nothing
    refute saver.run(saver.file_read_command(filename)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '2A0', %w(
  |file_create(filename,content) raises and does nothing
  |when filename aready exists as a file
  ) do
    dirname = 'client/N5/s2/A0'
    filename = dirname + '/events.json'
    content = '{"time":[3,4,5,6,7,8]}'
    dir_make(dirname)
    file_create(filename, content)
    message = 'command != true'
    assert_raises_SaverException(message,'write',filename,content*2) {
      file_create(filename,content*2)
    }
    assert_equal content, file_read(filename), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '2A1', %w(
  |file_create(filename,content) raises
  |when filename aready exists as a dir
  ) do
    dirname = 'client/N5/s2/A1'
    filename = dirname + '/events.json'
    content = '{"time":[3,4,5,6,7,8]}'
    dir_make(filename)
    message = 'command != true'
    assert_raises_SaverException(message,'write',filename,content) {
      file_create(filename,content)
    }
    refute saver.run(saver.file_read_command(filename)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '2A2', %w(
  |file_create(filename,content) raises
  |when filename is not a String
  ) do
    filename = 42
    content = '{"time":[3,4,5,6,7,8]}'
    message = 'malformed:command:write(key!=String):'
    assert_raises_SaverException(message,'write',filename,content) {
      file_create(filename,content)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '2A3', %w(
  |file_create(filename,content) raises and does nothing
  |when content is not a String
  ) do
    dirname = 'client/N5/s2/A3'
    filename = dirname + '/events.json'
    content = true
    dir_make(dirname)
    message = 'malformed:command:write(value!=String):'
    assert_raises_SaverException(message,'write',filename,content) {
      file_create(filename,content)
    }
    refute saver.run(saver.file_read_command(filename)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # file_append()

  multi_test '840', %w(
  |append(filename,content) returns true
  |and appends to the end of filename
  |when filename already exists
  ) do
    dirname = 'client/69/18/40'
    filename = dirname + '/readme.md'
    content = 'helloooo'
    dir_make(dirname)
    file_create(filename, content)
    assert file_append(filename, content)
    assert_equal content*2, file_read(filename)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '841', %w(
  |append(filename,content) raises and does nothing
  |when dir of filename does not already exist
  ) do
    dirname = 'client/96/18/41'
    filename = dirname + '/readme.md'
    content = '#readme'
    message = 'command != true'
    assert_raises_SaverException(message,'append',filename,content) {
      file_append(filename,content)
    }
    refute saver.run(saver.dir_exists_command(dirname)), :did_nothing
    refute saver.run(saver.file_read_command(filename)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '842', %w(
  |append(filename,content) raises and does nothing
  |when dir of filename exists but filename does not exist
  ) do
    dirname = 'client/96/18/42'
    filename = dirname + '/readme.md'
    content = '#readme'
    message = 'command != true'
    dir_make(dirname)
    assert_raises_SaverException(message,'append',filename,content) {
      file_append(filename,content)
    }
    refute saver.run(saver.file_read_command(filename)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '843', %w(
  |append(filename,content) raises and does nothing
  |when filename exists as a dir
  ) do
    dirname = 'client/96/18/43'
    filename = dirname + '/readme.md'
    content = '#readme'
    message = 'command != true'
    dir_make(filename)
    assert_raises_SaverException(message,'append',filename,content) {
      file_append(filename,content)
    }
    refute saver.run(saver.file_read_command(filename)), :did_nothing
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '844', %w(
  |append(filename,content) raises and does nothing
  |when filename is not a String
  ) do
    filename = nil
    content = '#readme'
    message = 'malformed:command:append(key!=String):'
    assert_raises_SaverException(message,'append',filename,content) {
      file_append(filename,content)
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  multi_test '845', %w(
  |append(filename,content) raises and does nothing
  |when conten is not a String
  ) do
    dirname = 'client/96/18/45'
    filename = dirname + '/readme.md'
    content = [34]
    message = 'malformed:command:append(value!=String):'
    assert_raises_SaverException(message,'append',filename,content) {
      file_append(filename,content)
    }
  end

=begin
  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # read()

  multi_test '437',
  'read(filename) reads what a successful write(filename,content) writes' do
    dirname = 'client/FD/F4/38'
    assert create(dirname)
    filename = dirname + '/limerick.txt'
    content = 'the boy stood on the burning deck'
    assert write(filename, content)
    assert_equal content, read(filename)
  end

  multi_test '438',
  'read() returns false given a non-existent file-name' do
    filename = 'client/1z/23/e4/not-there.txt'
    assert read(filename).is_a?(FalseClass)
  end

  multi_test '439',
  'read(filename) returns false given an existing dirname' do
    dirname = 'client/2f/7k/3P'
    create(dirname)
    assert read(dirname).is_a?(FalseClass)
  end
=end

  private

  def dir_make(dirname)
    saver.assert(dir_make_command(dirname))
  end

  def dir_exists?(dirname)
    saver.assert(dir_exists_command(dirname))
  end

  def file_create(filename, content)
    saver.assert(file_create_command(filename, content))
  end

  def file_append(filename, content)
    saver.assert(file_append_command(filename, content))
  end

  def file_read(filename)
    saver.assert(file_read_command(filename))
  end

  # - - - - - - - - - - - - - - - - - - - -

  def dir_make_command(dirname)
    saver.dir_make_command(dirname)
  end

  def dir_exists_command(dirname)
    saver.dir_exists_command(dirname)
  end

  def file_create_command(filename, content)
    saver.file_create_command(filename, content)
  end

  def file_append_command(filename, content)
    saver.file_append_command(filename, content)
  end

  def file_read_command(filename)
    saver.file_read_command(filename)
  end

  # - - - - - - - - - - - - - - - - - - - -

  def assert_raises_SaverException(message,*command)
    error = assert_raises(SaverService::Error) { yield }
    json = JSON.parse!(error.message)
    assert_equal '/assert', json['path'], :path
    expected_body = { 'command'=>command }
    assert_equal expected_body, JSON.parse!(json['body']), :body
    assert_equal 'SaverService', json['class'], :class
    assert_equal message, json['message'], :message
  end

end
