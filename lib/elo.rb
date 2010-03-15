# The configuration of Elo is done here.
#
# See README.rdoc for general information about Elo.
module Elo
  class Configuration

    def initialize
      @pro_rating_boundry = 2400
      @starter_boundry    = 30
      @default_rating     = 1000
      @default_k_factor   = 15
      @use_FIDE_settings  = true
    end

    # Add a K-factor rule. The first argument is the k-factor value.
    # The block should return a boolean that determines if this K-factor rule applies.
    # The first rule that applies is the one determining the K-factor.
    #
    # The block is instance_eval'ed into the player, so you can access all it's
    # properties directly. The K-factor is recalculated every time a match is played.
    #
    # By default, the FIDE settings are used (see: +use_FIDE_settings+). To implement
    # that yourself, you could write:
    #
    #   Elo.configure do |config|
    #     config.k_factor(10) { pro? or pro_rating? }
    #     config.k_factor(25) { starter? }
    #     config.default_k_factor = 15
    #   end
    #
    def k_factor(factor, &rule)
      k_factors << { :factor => factor, :rule => rule }
    end

    # This is the lower boundry of the rating you need to be a pro player.
    # This setting is used in the FIDE k-factor rules. (default = 2400)
    attr_accessor :pro_rating_boundry

    # This is the lower boundry in the amount of games played to be a starting player
    # This setting is used in the FIDE k-factor rules. (default = 30)
    attr_accessor :starter_boundry

    # The default k-factor is chosen when no k-factor rules apply.
    # K-factor rules can be added by using the +k_factor+-method. (default = 15)
    attr_accessor :default_k_factor

    # This is the rating every player starts out with. (default = 1000)
    attr_accessor :default_rating

    # Use the settings that FIDE use for determening the K-factor.
    # This is the case when all settings are unaltered. (default = true)
    # 
    # In short:
    # 
    # * K-factor is 25 when a player is a starter (less than 30 games played)
    # * K-factor is 10 when a player is a pro (rating above 2400, now or in the past)
    # * K-factor is 15 when a player in other cases
    #
    # If you want to use your own settings, either change the boundry settings,
    # or set this setting to false and add you're own k-factor rules.
    # K-factor rules can be added by using the +k_factor+-method.
    attr_accessor :use_FIDE_settings

    def applied_k_factors
      apply_fide_k_factors if use_FIDE_settings
      k_factors
    end

    private

    def k_factors
      @k_factors ||= []
    end

    def apply_fide_k_factors
      unless @applied_fide_k_factors
        k_factor(10) { pro? or pro_rating? }
        k_factor(25) { starter? }
        @applied_fide_k_factors = true
      end
    end

  end

  def self.config
    @config ||= Configuration.new
  end

  # Configure Elo in a block style.
  #
  #   Elo.configure do |config|
  #     config.setting = value
  #   end
  def self.configure(&block)
    yield(config)
  end


  # Common methods for Elo classes.
  module EloHelper

    def self.included(base)
      base.extend ClassMethods
    end

    # Every object can be initialized with a hash, just like in ActiveRecord.
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

  # A player. You need at least two play a Game.
  class Player

    include EloHelper

    # Rating
    def rating
      @rating ||= Elo.config.default_rating
    end

    def games_played
      @games_played ||= games.size
    end

    def games
      @games ||= []
    end

    def pro_rating?
      rating >= Elo.config.pro_rating_boundry
    end

    def starter?
      games_played < Elo.config.starter_boundry
    end

    def pro?
      !!@pro
    end

    # TODO
    def save
      # hook for your own model
      # which I don't know yet how to do
    end

    def k_factor
      return @k_factor if @k_factor
      Elo.config.applied_k_factors.each do |rule|
        return rule[:factor] if instance_eval(&rule[:rule])
      end
      Elo.config.default_k_factor
    end

    def versus(other_player)
      Game.new(:one => self, :two => other_player)
    end

    def wins_from(other_player)
      versus(other_player).win
    end

    def plays_draw(other_player)
      versus(other_player).draw
    end

    def loses_from(other_player)
      versus(other_player).lose
    end

    private

    # A Game tells the players informed to update their
    # scores, after it knows the result (so it can calculate the rating).
    #
    # This method is private, because it is called automatically.
    # Therefore it is not part of the public API of Elo.
    def played(game)
      @games_played = games_played + 1
      games << game
      @rating = game.new_rating(self)
      @pro    = true if pro_rating?
      save
    end


  end

  class Game

    include EloHelper

    def inspect
      [one.rating, two.rating, result].join('::')
    end

    attr_reader :result
    attr_reader :one
    attr_reader :two

    # Result is from the perspective of player one.
    def process_result(result)
      @result = result
      one.send(:played, self)
      two.send(:played, self)
      save
      self
    end
    alias result= process_result

    def win
      process_result 1.0
    end

    def lose
      process_result 0.0
    end

    def draw
      process_result 0.5
    end

    # TODO
    def save
    end

    def winner=(player)
      process_result(player == :one ? 1.0 : 0.0)
    end

    def loser=(player)
      process_result(player == :one ? 0.0 : 1.0)
    end

    def new_rating(player)
      ratings[player].new_rating
    end

    private

    def ratings
      @ratings ||= { one => rating_one, two => rating_two }
    end

    def rating_one
      Rating.new(:result        => result,
                 :old_rating    => one.rating,
                 :other_rating  => two.rating,
                 :k_factor      => one.k_factor)
    end

    def rating_two
      Rating.new(:result        => (1.0 - result),
                 :old_rating    => two.rating,
                 :other_rating  => one.rating,
                 :k_factor      => two.k_factor)
    end

  end

  class Rating

    include EloHelper

    attr_reader :other_rating
    attr_reader :old_rating
    attr_reader :k_factor

    def result
      raise "Invalid result: #{@result.inspect}" unless valid_result?
      @result.to_f
    end

    def valid_result?
      (0..1).include? @result
    end

    def expected
      1.0 / ( 1.0 + ( 10.0 ** ((other_rating.to_f - old_rating.to_f) / 400.0) ) )
    end

    def change
      k_factor.to_f * ( result.to_f - expected )
    end

    def new_rating
      (old_rating.to_f + change).to_i
    end

  end

end
