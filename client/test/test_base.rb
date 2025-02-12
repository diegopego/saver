require_relative 'id58_test_base'
require_relative 'capture_stdout_stderr'
require_relative 'kata_test_data'
require_source 'externals'

class TestBase < Id58TestBase

  include CaptureStdoutStderr
  include KataTestData

  def initialize(arg)
    super(arg)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - -

  def externals
    @exernals ||= Externals.new
  end

  def saver
    externals.saver
  end

  # - - - - - - - - - - - - - - - - - -

  def group_create_custom(version, display_name)
    saver.group_create_custom(version, display_name)
  end

  def group_create(version, ltf_name, exercise_name)
    saver.group_create(version, ltf_name, exercise_name)
  end

  def group_exists?(id)
    saver.group_exists?(id)
  end

  def group_manifest(id)
    saver.group_manifest(id)
  end

  def group_join(id, indexes=(0..63).to_a.shuffle)
    saver.group_join(id, indexes)
  end

  def group_joined(id)
    saver.group_joined(id)
  end

  def group_fork(id, index)
    saver.group_fork(id, index)
  end

  # - - - - - - - - - - - - - - - - - -

  def kata_create_custom(version, display_name)
    saver.kata_create_custom(version, display_name)
  end

  def kata_create(version, ltf_name, exercise_name)
    saver.kata_create(version, ltf_name, exercise_name)
  end

  def kata_exists?(id)
    saver.kata_exists?(id)
  end

  def kata_manifest(id)
    saver.kata_manifest(id)
  end

  def kata_events(id)
    saver.kata_events(id)
  end

  def kata_event(id, index)
    saver.kata_event(id, index)
  end

  def katas_events(ids, indexes)
    saver.katas_events(ids, indexes)
  end

  def kata_option_get(name)
    saver.kata_option_get(id, name)
  end

  def kata_option_set(name, value)
    saver.kata_option_set(id, name, value)
  end

  def kata_fork(id, index)
    saver.kata_fork(id, index)
  end

  # - - - - - - - - - - - - - - - - - -

  def self.versions_test(id58_suffix, *lines, &block)
    current_version = 2
    versions = (0..current_version)
    versions.each do |version|
      version_test(version, id58_suffix, *lines, &block)
    end
  end

  def self.version_test(version, id58_suffix, *lines, &block)
    lines.unshift("<version:#{version}>")
    test(id58_suffix, *lines, version) do
      self.instance_eval(&block)
    end
  end

  def in_group_custom
    display_name = any_custom_start_points_display_name
    id = group_create_custom(version, display_name)
    yield id, display_name
  end

  def in_group
    ltf_name = any_languages_start_points_display_name
    exercise_name = any_exercises_start_points_display_name
    id = group_create(version, ltf_name, exercise_name)
    yield id, ltf_name, exercise_name
  end

  def in_kata_custom
    display_name = any_custom_start_points_display_name
    id = kata_create_custom(version, display_name)
    yield id, display_name
  end

  def in_kata
    ltf_name = any_languages_start_points_display_name
    exercise_name = any_exercises_start_points_display_name
    id = kata_create(version, ltf_name, exercise_name)
    yield id, ltf_name, exercise_name
  end

  def any_custom_start_points_display_name
    custom_start_points.display_names.sample
  end

  def any_exercises_start_points_display_name
    exercises_start_points.display_names.sample
  end

  def any_languages_start_points_display_name
    languages_start_points.display_names.sample
  end

  def custom_start_points
    externals.custom_start_points
  end

  def exercises_start_points
    externals.exercises_start_points
  end

  def languages_start_points
    externals.languages_start_points
  end

  #def custom_manifest
  #  @display_name = custom_start_points.display_names.sample
  #  manifest = custom_start_points.manifest(display_name)
  #  manifest['version'] = version
  #  manifest
  #end

  # - - - - - - - - - - - - - - - - - -

  def two_timed(n, algos)
    t0,t1 = 0,0
    n.times do
      # which one to do first?
      if rand(42) % 2 == 0
        t0 += timed { algos[0].call }
        t1 += timed { algos[1].call }
      else
        t1 += timed { algos[1].call }
        t0 += timed { algos[0].call }
      end
    end
    [t0,t1]
  end

  def timed
    started_at = clock_time
    yield
    finished_at = clock_time
    (finished_at - started_at)
  end

  def clock_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

end
