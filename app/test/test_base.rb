require_relative 'id58_test_base'
require_relative 'capture_stdout_stderr'
require_relative 'data/kata_test_data'
require_relative 'doubles/disk_fake'
require_relative 'doubles/random_stub'
require_relative 'doubles/time_stub'
require_relative 'helpers/disk'
require_relative 'helpers/externals'
require_relative 'helpers/model'
require_relative 'helpers/rack'
require_relative 'require_source'
require 'json'

class TestBase < Id58TestBase

  def initialize(arg)
    super(arg)
  end

  include CaptureStdoutStderr
  include KataTestData
  include TestHelpersDisk
  include TestHelpersExternals
  include TestHelpersModel
  include TestHelpersRack


  # - - - - - - - - - - - - - - - - - - -

  def in_group(&block)
    @display_name = languages_start_points.display_names.sample
    @exercise_name = exercises_start_points.display_names.sample
    yield group_create(version, @display_name, @exercise_name)
  end

  def in_kata(gid=nil, &block)
    if gid.nil?
      @display_name = languages_start_points.display_names.sample
      @exercise_name = exercises_start_points.display_names.sample
      yield kata_create(version, @display_name, @exercise_name)
    else
      yield group_join(gid)
    end
  end

  def custom_manifest
    display_name = custom_start_points.display_names.sample
    custom_start_points.manifest(display_name)
  end

  # - - - - - - - - - - - - - - - - - - -

  def self.disk_tests(id58_suffix, *lines, &block)
    test(id58_suffix, ["<disk:Real>"]+lines) do
      self.instance_exec(&block)
    end
    test(id58_suffix, ["<disk:Fake>"]+lines) do
      self.externals.instance_variable_set("@disk", DiskFake.new)
      self.instance_eval(&block)
    end
  end

  # - - - - - - - - - - - - - - - - - - -

  def self.versions_test(id58_suffix, *lines, &block)
    versions = (0..Model::CURRENT_VERSION)
    versions.each do |version|
      version_test(version, id58_suffix, *lines, &block)
    end
  end

  def self.versions3_test(id58_suffix, *lines, &block)
    versions = (0..2)
    versions.each do |version|
      version_test(version, id58_suffix, *lines, &block)
    end
  end

  def self.version_test(version, id58_suffix, *lines, &block)
    lines.unshift("<version:#{version}>")
    test(id58_suffix, *lines) do
      @version = version
      self.instance_exec(&block)
    end
  end

  def version
    @version
  end

end
