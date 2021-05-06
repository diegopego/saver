# frozen_string_literal: true
require_relative '../external/custom_start_points'
require_relative '../require_source'
require_source 'externals'

module TestHelpersExternals

  def externals
    @externals ||= Externals.new
  end

  def custom_start_points
    External::CustomStartPoints.new
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

  def time
    externals.time
  end

end
