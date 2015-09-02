module Elo

	module Helper

    # Every object can be initialized with a hash,
		# almost, but not quite, entirely unlike ActiveRecord.
    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

	end

end
