require 'jq'

module JQ::Extend
  def jq(program, &block)
    src = JQ::Parser.json_driver.dump(self)
    JQ(src).search(program, &block)
  end
end

class Hash;  include JQ::Extend; end
class Array; include JQ::Extend; end
