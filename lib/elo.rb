require 'elo/helper'
require 'elo/configuration'
require 'elo/game'
require 'elo/player'
require 'elo/rating'

# See README.rdoc for general information about Elo.
module Elo

  # Accessor to the configuration object, which,
  # should be instantiated only once (and automatically).
  def self.config
    @config ||= Configuration.new
  end

  # Configure Elo in a block style.
  # See Elo::Configuration for more details.
  #
  #   Elo.configure do |config|
  #     config.attribute = :value
  #   end
  def self.configure(&block)
    yield(config)
  end

end
