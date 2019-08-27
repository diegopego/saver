# frozen_string_literal: true

require_relative 'kata'
require_relative 'liner'
require 'json'

class Group

  def initialize(externals)
    @externals = externals
  end

  # - - - - - - - - - - - - - - - - - - -

  def exists?(id)
    saver.exists?(id_path(id))
  end

  # - - - - - - - - - - - - - - - - - - -

  def create(manifest)
    id = manifest['id'] = group_id_generator.id
    manifest['visible_files'] = lined_files(manifest['visible_files'])
    key = id_path(id, manifest_filename)
    value = json_pretty(manifest)
    unless saver.write(key, value)
      fail invalid('id', id)
    end
    id
  end

  # - - - - - - - - - - - - - - - - - - -

  def manifest(id)
    key = id_path(id, manifest_filename)
    manifest_src = saver.read(key)
    unless manifest_src
      fail invalid('id', id)
    end
    manifest = json_parse(manifest_src)
    manifest['visible_files'] = unlined_files(manifest['visible_files'])
    manifest
  end

  # - - - - - - - - - - - - - - - - - - -

  def join(id, indexes)
    unless exists?(id)
      fail invalid('id', id)
    end
    commands = indexes.map { |new_index|
      [ 'write', id_path(id, new_index, 'kata.id'), '' ]
    }
    results = saver.batch_until_true(commands)
    n = results.index(true)
    if n.nil?
      nil
    else
      index = indexes[n]
      manifest = self.manifest(id)
      manifest.delete('id')
      manifest['group_id'] = id
      manifest['group_index'] = index
      kata_id = kata.create(manifest)
      saver.append(id_path(id, index, 'kata.id'), kata_id)
      kata_id
    end
  end

  # - - - - - - - - - - - - - - - - - - -

  def joined(id)
    if !exists?(id)
      nil
    else
      kata_indexes(id).map{ |kata_id,_| kata_id }
    end
  end

  # - - - - - - - - - - - - - - - - - - -

  def events(id)
    if !exists?(id)
      events = nil
    else
      indexes = kata_indexes(id)
      filenames = indexes.map do |kata_id,_index|
        args = ['', 'katas']
        args += [kata_id[0..1], kata_id[2..3], kata_id[4..5]]
        args += ['events.json']
        File.join(*args)
      end
      katas_events = saver.batch_read(filenames)
      events = {}
      indexes.each.with_index(0) do |(kata_id,index),offset|
        events[kata_id] = {
          'index' => index,
          'events' => group_events_parse(katas_events[offset])
        }
      end
    end
    events
  end

  private

  def exists_cmd(id, *parts)
    ['exists?', id_path(id, *parts)]
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def id_path(id, *parts)
    # Using 2/2/2 split.
    # See https://github.com/cyber-dojo/id-split-timer
    args = ['', 'groups', id[0..1], id[2..3], id[4..5]]
    args += parts.map(&:to_s)
    File.join(*args)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  include Liner

  def kata_indexes(id)
    filenames = (0..63).map do |index|
      id_path(id, index, 'kata.id')
    end
    reads = saver.batch_read(filenames)
    reads.each.with_index(0).select{ |kata_id,_| kata_id }
  end

  def manifest_filename
    'manifest.json'
  end

  # - - - - - - - - - - - - - -

  def group_events_parse(s)
    JSON.parse!('[' + s.lines.join(',') + ']')
    # Alternative implementation, which tests show is slower.
    # s.lines.map { |line| JSON.parse!(line) }
  end

  # - - - - - - - - - - - - - -

  def json_pretty(o)
    JSON.pretty_generate(o)
  end

  def json_parse(s)
    JSON.parse!(s)
  end

  # - - - - - - - - - - - - - -

  def invalid(name, value)
    ArgumentError.new("#{name}:invalid:#{value}")
  end

  # - - - - - - - - - - - - - -

  def saver
    @externals.saver
  end

  def group_id_generator
    @externals.group_id_generator
  end

  def kata
    @externals.kata
  end

end