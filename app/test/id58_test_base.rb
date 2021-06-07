require_relative 'require_source'
require 'minitest/autorun'
require 'rack/test'

class Id58TestBase < MiniTest::Test

  def initialize(arg)
    @id58 = nil
    @name58 = nil
    super
  end

  @@args = (ARGV.sort.uniq - ['--']) # eg 2m4
  @@seen_ids = {}
  @@timings = {}

  # - - - - - - - - - - - - - - - - - - - - - -

  # :nocov:
  def self.test(id58_suffix, *lines, &test_block)
    source_file, source_line = *self.location(&test_block)
    id58 = checked_id58(id58_suffix.to_s, lines)
    if @@args === [] || @@args.any?{ |arg| id58.include?(arg) }
      name58 = lines.join(' ').split('|').join("\n|")
      execute_around = lambda {
        ENV['ID58'] = id58
        @id58 = id58
        @name58 = name58
        id58_setup
        begin
          t1 = Time.now
          self.instance_exec(&test_block)
          t2 = Time.now
          stripped = trimmed(name58.split("\n").join)
          @@timings[id58+' '+source_file+':'+source_line+' '+stripped] = (t2 - t1)
        ensure
          unless $!.nil?
            puts($!.message)
          end
          id58_teardown
        end
      }
      name = "#{id58_prefix}#{id58_suffix}\n#{name58}"
      define_method("test_\n#{name}".to_sym, &execute_around)
    end
  end

  BASE_DIR = File.dirname(__FILE__) + '/'

  def self.location(&test_block)
    callers = test_block.send('caller')
    it = callers.find { |entry| is_test_filename?(entry) }
    match = it.match(/(.*):(\d+):/)
    filename = match[1][BASE_DIR.size..-1]
    line = match[2]
    [ filename, line ]
  end

  def self.is_test_filename?(filename)
    !filename.start_with?("#{BASE_DIR}id58_test_base.rb:") &&
      !filename.start_with?("#{BASE_DIR}test_base.rb:")
  end

  def trimmed(s)
    if s.length > 80
      s[0..80] + '...'
    else
      s
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  MiniTest.after_run do
    slow = @@timings.select{ |_name,secs| secs > 0.000 }
    sorted = slow.sort_by{ |name,secs| -secs }.to_h
    max_shown = 5
    size = sorted.size < max_shown ? sorted.size : max_shown
    puts
    if size != 0
      puts "Slowest #{size} tests in /app/test/ are..."
    end
    sorted.each.with_index { |(name,secs),index|
      puts "%3.4f %-72s" % [secs,name]
      if index === size
        break
      end
    }
    puts
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  ID58_ALPHABET = %w{
    0 1 2 3 4 5 6 7 8 9
    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    a b c d e f g h i j k l m n o p q r s t u v w x y z
  }.join.tr('IiOo','').freeze

  def self.id58?(s)
    s.instance_of?(String) &&
      s.chars.all?{ |ch| ID58_ALPHABET.include?(ch) }
  end

  def self.checked_id58(id58_suffix, lines)
    method = 'def self.id58_prefix'
    pointer = ' ' * method.index('.') + '!'
    pointee = (['',pointer,method,'','']).join("\n")
    pointer.prepend("\n\n")
    raise "#{pointer}missing#{pointee}" unless respond_to?(:id58_prefix)
    prefix = id58_prefix.to_s
    raise "#{pointer}empty#{pointee}" if prefix === ''
    raise "#{pointer}not id58#{pointee}" unless id58?(prefix)

    method = "test '#{id58_suffix}',"
    pointer = ' ' * method.index("'") + '!'
    proposition = lines.join(' ').split('|').join("\n|")
    pointee = ['',pointer,method,"'#{proposition}'",'',''].join("\n")
    id58 = prefix + id58_suffix
    pointer.prepend("\n\n")
    raise "#{pointer}empty#{pointee}" if id58_suffix === ''
    raise "#{pointer}not id58#{pointee}" unless id58?(id58_suffix)
    raise "#{pointer}duplicate#{pointee}" if duplicate?(id58)
    raise "#{pointer}overlap#{pointee}" if prefix[-2..-1] === id58_suffix[0..1]
    id58
  end

  def self.duplicate?(id58)
    @@seen_ids[id58] ||= 0
    @@seen_ids[id58] += 1
    @@seen_ids[id58] > 3
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def id58_setup
  end

  def id58_teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def id58
    @id58
  end

  def name58
    @name58
  end
  # :nocov:

end
