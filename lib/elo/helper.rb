module Elo

	module Helper

    def self.included(base)
      base.extend ClassMethods
    end

    # Every object can be initialized with a hash,
		# almost, but not quite, entirely unlike ActiveRecord.
    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      self.class.all << self
    end

    module ClassMethods

      # Provides a list of all instantiated objects of the class.
      def all
        @all ||= []
      end

    end

	end

end
