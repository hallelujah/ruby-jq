class JQ::Parser
  BUFSIZ = 4096

  def initialize(src, options = {})
    @src = kind_of_io?(src) ? src : src.to_s
    @options = {
      parse_json: true,
    }.merge(options)
  end

  def search(program, &block)
    @src.rewind if kind_of_io?(@src)
    retval = nil

    if block
      block_orig = block

      block = proc do |str|
        block_orig.call(parse_json(str))
      end
    else
      retval = []

      block = proc do |str|
        retval << parse_json(str)
      end
    end

    jq(program) do |jq_core|
      if kind_of_io?(@src)
        while buf = @src.read(BUFSIZ)
          jq_core.update(buf, !@src.eof?, &block)
        end
      else
        jq_core.update(@src, false, &block)
      end
    end

    return retval
  end

  def json_driver
    @json_driver ||= @options[:json_driver] || self.class.json_driver
  end

  def self.json_driver
    begin
      JSON
    rescue NameError
      require 'json'
      JSON
    end
  end

  private
  def jq(program)
    jq_core = nil

    begin
      jq_core = JQ::Core.new(program)
      retval = yield(jq_core)
    ensure
      jq_core.close if jq_core
    end
  end

  def parse_json(str)
    if @options[:parse_json]
      json_driver.load("[#{str}]").first
    else
      str
    end
  end

  def kind_of_io?(obj)
    [IO, Tempfile, StringIO].any? {|c| obj.kind_of?(c) }
  end
end
