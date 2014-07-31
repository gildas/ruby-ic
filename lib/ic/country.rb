module Ic
  class Country
    attr_reader :id, :name

    def initialize(options = {})
      raise MissingArgumentError, 'id' unless options[:id]
      @id   = options[:id]
      @name = options[:name] || options[:displayName]
    end
  end
end