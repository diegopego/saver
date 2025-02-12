require_relative 'fork'
require_relative 'id_generator'
require_relative 'id_pather'
require_relative 'options'
require_relative 'poly_filler'
require_relative '../lib/json_adapter'
require_relative '../lib/tarfile_reader'
require_relative '../lib/utf8_clean'
require 'tmpdir'

# 1. Uses git repo to store date
# 2. event.json has been dropped
# 3. event_summary.json is now called events.json and contains a json array
# 4. entries in events.json have strictly sequential indexes
# 5. saver outages are recorded in events_summary.json

class Kata_v2

  def initialize(externals)
    @externals = externals
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def create(manifest)
    manifest['version'] = 2
    manifest['created'] = time.now
    events = [{
      'index' => 0,
      'event' => 'created',
      'time'  => manifest['created']
    }]
    files = manifest.delete('visible_files')

    # IdGenerator makes the kata dir, eg /cyber-dojo/katas/Rl/mR/cV
    id = manifest['id'] = IdGenerator.new(@externals).kata_id
    disk.assert_all([
      disk.file_create_command(manifest_filename(id), json_pretty(manifest)),
      disk.file_create_command(options_filename(id), json_pretty(default_options)),
      disk.file_create_command(events_filename(id), json_pretty(events)),
      disk.file_create_command(readme_filename(id), readme(manifest))
    ])

    files_dir = "#{kata_dir(id)}/files"
    write_files(disk, files_dir, content_of(files))

    shell.assert_cd_exec(repo_dir(id), [
      "git init --quiet",
      "git config user.name '#{id}'",
      "git config user.email '#{id}@cyber-dojo.org'",
      "git add .",
      "git commit --message '0 kata creation' --quiet",
      "git tag 0 HEAD",
      "git branch -m master main"
    ])

    id
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def manifest(id)
    result = read_manifest(id)
    polyfill_manifest_defaults(result)
    result
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def events(id)
    result = read_events(disk, id)
    #TODO: polyfill_events_defaults(result)
    result
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def event(id, index)
    result = { "files" => {} }
    index = index.to_i
    if index < 0
      index = events(id)[index]['index']
    end

    truncations = nil
    tar_file = shell.assert_cd_exec(repo_dir(id), "git archive --format=tar #{index}")
    reader = TarFile::Reader.new(tar_file)
    reader.files.each do |filename, content|
      if filename[-1] === '/' # dir marker
        next
      elsif filename.start_with?("files/")
        result["files"][filename["files/".size..-1]] = {
          "content" => content
        }
      elsif ["stdout", "stderr"].include?(filename)
        result[filename] = {
          "content" => content
        }
      elsif filename === "status"
        result["status"] = content
      elsif filename === "events.json"
        event = json_parse(content)[index]
        result.merge!(event)
      elsif filename === "truncations.json"
        truncations = json_parse(content)
      end
    end

    if result["event"] == "outage"
      ["stdout", "stderr", "status"].each { |f| result.delete(f) }
    elsif result.has_key?('stdout')
      result['stdout']['truncated'] = truncations['stdout']
      result['stderr']['truncated'] = truncations['stderr']
    end

    result
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def event_batch(ids, indexes)
    ids.zip(indexes).each.with_object({}) do |(id,index),hash|
      hash[id] ||= {}
      hash[id][index.to_s] = event(id, index)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def ran_tests(id, index, files, stdout, stderr, status, summary)
    message = "ran tests, no prediction, got #{summary['colour']}"
    git_commit_tag(id, index, files, stdout, stderr, status, summary, message)
  end

  def predicted_right(id, index, files, stdout, stderr, status, summary)
    message = "ran tests, predicted #{summary['predicted']}, got #{summary['colour']}"
    git_commit_tag(id, index, files, stdout, stderr, status, summary, message)
  end

  def predicted_wrong(id, index, files, stdout, stderr, status, summary)
    message = "ran tests, predicted #{summary['predicted']}, got #{summary['colour']}"
    git_commit_tag(id, index, files, stdout, stderr, status, summary, message)
  end

  def reverted(id, index, files, stdout, stderr, status, summary)
    revert = summary['revert']
    info = json_plain({ "id" => revert[0], "index" => revert[1] })
    message = "reverted to #{info.inspect}"
    git_commit_tag(id, index, files, stdout, stderr, status, summary, message)
  end

  def checked_out(id, index, files, stdout, stderr, status, summary)
    info = json_plain(summary['checkout'])
    message = "checked out #{info.inspect}"
    git_commit_tag(id, index, files, stdout, stderr, status, summary, message)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def option_get(id, name)
    fail_unless_known_option(name)
    read_options(disk, id)[name]
  end

  def option_set(id, name, value)
    fail_unless_known_option(name)
    possibles = (name === 'theme') ? ['dark','light'] : ['on', 'off']
    unless possibles.include?(value)
      fail "Cannot set theme to #{value}, only to one of #{possibles}"
    end
    if option_get(id, name) === value
      return
    end
    git_ff_merge_worktree(repo_dir(id)) do |worktree|
      options = read_options(worktree)
      options[name] = value
      write_files(worktree, '', { options_filename => json_pretty(options) })
      shell.assert_cd_exec(worktree.root_dir, [
        "git add .",
        "git commit --allow-empty --all --message 'set option #{name} to #{value}' --quiet",
      ])
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def download(id)
    # If id == 'vqzjS7' then repo_dir(id) is '/cyber-dojo/katas/vq/zj/S7/'
    # and the root-dir of the tar command is 'S7'.
    # So using --transform to create root-dir with a name
    # matching the tzg filename itself.
    year, month, day = *time.now
    user_name = "cyber-dojo-#{year}-#{month}-#{day}-#{id}"
    Dir.mktmpdir do |tmp_dir|
      tgz_command = "tar -czf #{tmp_dir}/#{user_name}.tgz --transform s/^./#{user_name}/ ."
      shell.assert_cd_exec(repo_dir(id), tgz_command)
      tgz_file_path = "#{tmp_dir}/#{user_name}.tgz"
      [ "#{user_name}.tgz", Base64.encode64(File.read(tgz_file_path)) ]
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  include Fork
  include Options

  private

  include IdPather
  include JsonAdapter
  include PolyFiller

  # - - - - - - - - - - - - - - - - - - - - - -

  def readme_filename(id)
    kata_id_path(id, "README.md")
  end

  def readme(manifest)
    id = manifest['id']
    exercise = manifest['exercise']
    display_name = manifest['display_name']

    if exercise.nil?
      info = "- Custom exercise: `#{display_name}`\n"
    else
      info = [
        "- Exercise: `#{exercise}`",
        "- Language & test-framework: `#{display_name}`",
      ].join("\n")
    end
    [
      "# This a copy of [your cyber-dojo exercise](https://cyber-dojo.org/kata/edit/#{id}):",
      info,
      "",
      "## How to upload your cyber-dojo exercise to GitHub:",
      "- Go to your github on browser.",
      "- Create a new repo for your cyber-dojo practice. For example `cyber-dojo-2021-7-11-bR2hnf`",
      "- Execute the instructions shown in GitHub to 'push an existing repository from the command line'",
      "The instructions will look like this:",
      "```",
      "git remote add origin https://github.com/diegopego/cyber-dojo-2021-7-11-bR2hnf.git",
      "git branch -M main",
      "git push -u origin main",
      "```",
    ].join("\n")
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def git_commit_tag(id, index, files, stdout, stderr, status, summary, message)
    saver_outages = nil
    git_ff_merge_worktree(repo_dir(id)) do |worktree|
      # Update events in worktree
      events = read_events(worktree)
      last_index = events.last['index']
      unless index > last_index
        raise "Out of order event"
      end
      # Backfill saver outage events
      saver_outages = (last_index+1..index-1)
      saver_outages.each do |n|
        events << { 'index' => n, 'event' => 'outage' }
      end
      # Add the new event
      events << summary.merge!({ 'index' => index, 'time' => time.now })
      write_files(worktree, '', { events_filename => json_pretty(events) })

      # Remove files/
      shell.assert_cd_exec(worktree.root_dir, "git rm -r files/")
      # Add new files/
      write_files(worktree, "files", content_of(files))

      # Update metadata
      write_files(worktree, '', {
        "stdout" => stdout['content'],
        "stderr" => stderr['content'],
        "status" => status.to_s,
        "truncations.json" => json_pretty({
          "stdout" => stdout["truncated"],
          "stderr" => stderr["truncated"]
        })
      })

      # Add all files and commit
      shell.assert_cd_exec(worktree.root_dir, [
        "git add .",
        "git commit --message '#{index} #{message}' --quiet",
      ])
    end
    # Merge succeeded, tag
    shell.assert_cd_exec(repo_dir(id), ["git tag #{index} HEAD"])
    saver_outages.each do |n|
      shell.assert_cd_exec(repo_dir(id), ["git tag #{n} HEAD"])
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def git_ff_merge_worktree(repo_dir)
    branch = random.alphanumeric(8)
    worktree_dir = "/tmp/#{branch}"
    shell.assert_cd_exec(repo_dir, "git worktree add #{worktree_dir}")
    worktree = External::Disk.new(worktree_dir)
    yield worktree
    shell.assert_cd_exec(repo_dir, "git merge --ff-only #{branch}")
  ensure
    shell.assert_cd_exec(repo_dir,
      "git worktree remove --force #{branch}",
      "git branch --delete --force #{branch}",
      "rm -rf #{worktree_dir}"
    )
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def read_events(disk, id=nil)
    # eg
    # [
    #  { "index": 0, ..., "event": "created" },
    #  { "index": 1, ..., "colour": "red"    },
    #  { "index": 2, ..., "colour": "amber"  }
    # ]
    read_json(disk, events_filename(id))
  end

  def read_options(disk, id=nil)
    read_json(disk, options_filename(id))
  end

  def read_manifest(id)
    # eg { "display_name": "Ruby, MiniTest",...}
    read_json(disk, manifest_filename(id))
  end

  def read_json(disk, filename)
    json_parse(read(disk, filename))
  end

  def read(disk, filename)
    command = disk.file_read_command(filename)
    content = disk.assert(command)
    Utf8.clean(content)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def manifest_filename(id)
    # eg id == 'SyG9sT' ==> '/katas/Sy/G9/sT/manifest.json'
    kata_id_path(id, "manifest.json")
  end

  def options_filename(id=nil)
    # eg id == 'SyG9sT' ==> '/katas/Sy/G9/sT/options.json'
    if id.nil?
      "options.json"
    else
      kata_id_path(id, options_filename)
    end
  end

  def events_filename(id=nil)
    # eg id == 'SyG9sT' ==> '/katas/Sy/G9/sT/events.json'
    if id.nil?
      "events.json"
    else
      kata_id_path(id, events_filename)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def fail_unless_known_option(name)
    unless %w( theme colour predict revert_red revert_amber revert_green ).include?(name)
      fail "Unknown option #{name}"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def write_files(disk, base_dir, files)
    make_dirs(disk, base_dir, files)
    commands = files.each.with_object([]) do |(filename,content),array|
      path = "#{base_dir}/#{filename}"
      array << disk.file_write_command(path, content)
    end
    disk.assert_all(commands)
  end

  def make_dirs(disk, base_dir, files)
    dirs = files.keys.each.with_object([]) do |filename, array|
      path = "#{base_dir}/#{filename}"
      array << File.dirname(path)
    end
    commands = (dirs.uniq.sort - ['/']).map{|dir| disk.dir_make_command(dir)}
    # Eg [ 'a/b', 'a/b/c' ] which must be created in that order
    # because the make_dir command is not idempotent.
    disk.assert_all(commands)
  end

  def repo_dir(id)
    # eg /cyber-dojo/katas/R2/mR/cV
    '/' + disk.root_dir + '/' + kata_dir(id)
  end

  def kata_dir(id)
    kata_id_path(id) # relative to /cyber-dojo/ eg '/katas/R2/mR/cV
  end

  def content_of(files)
    files.map{|filename,file| [filename,file['content']]}.to_h
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def disk
    @externals.disk
  end

  def random
    @externals.random
  end

  def shell
    @externals.shell
  end

  def time
    @externals.time
  end

end
