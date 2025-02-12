require_relative '../require_source'
require_source 'externals'

module TestHelpersExternals

  def externals
    @externals ||= Externals.new
  end

  def disk
    externals.disk
  end

  def model
    externals.model
  end

  def prober
    externals.prober
  end

  def random
    externals.random
  end

  def shell
    externals.shell
  end

  def time
    externals.time
  end

  # - - - - - - - - - - - - - - - - -

  def custom_start_points
    externals.custom_start_points
  end

  def exercises_start_points
    externals.exercises_start_points
  end

  def languages_start_points
    externals.languages_start_points
  end

end
