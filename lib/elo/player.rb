module Elo

  # A player. You need at least two play a Game.
  class Player

    include Helper

    # The rating you provided, or the default rating from configuration
    def rating
      @rating ||= Elo.config.default_rating
    end

		# The number of games played is needed for calculating the K-factor.
    def games_played
      @games_played ||= games.size
    end

		# A list of games played by the player.
    def games
      @games ||= []
    end

		# Is the player considered a pro, because his/her rating crossed
		# the threshold configured? This is needed for calculating the K-factor.
    def pro_rating?
      rating >= Elo.config.pro_rating_boundry
    end

		# Is the player just starting? Provide the boundry for
		# the amount of games played in the configuration.
		# This is needed for calculating the K-factor.
    def starter?
      games_played < Elo.config.starter_boundry
    end

		# FIDE regulations specify that once you reach a pro status
		# (see +pro_rating?+), you are considered a pro for life.
		#
		# You might need to specify it manually, when depending on
		# external persistence of players.
		#
		#		Elo::Player.new(:pro => true)
    def pro?
      !!@pro
    end

    # You can override this method if you store each game
		# in a database or something like that.
		# This method will be called when a result is known.
    def save
    end

		# Calculates the K-factor for the player.
		# Elo allows you specify custom Rules (see Elo::Configuration).
		#
		# You can set it manually, if you wish:
		#
		#		Elo::Player.new(:k_factor => 10)
		#
		#	This stops this player from using the K-factor rules.
    def k_factor
      return @k_factor if @k_factor
      Elo.config.applied_k_factors.each do |rule|
        return rule[:factor] if instance_eval(&rule[:rule])
      end
      Elo.config.default_k_factor
    end

		# Start a game with another player. At this point, no
		# result is known and nothing really happens.
    def versus(other_player, options = {})
      Game.new(options.merge(:one => self, :two => other_player)).calculate
    end

		# Start a game with another player and set the score
		# immediately.
    def wins_from(other_player, options = {})
      versus(other_player, options).win
    end

		# Start a game with another player and set the score
		# immediately.
    def plays_draw(other_player, options = {})
      versus(other_player, options).draw
    end

		# Start a game with another player and set the score
		# immediately.
    def loses_from(other_player, options = {})
      versus(other_player, options).lose
    end

    def inspect
      "player"
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
      @rating = game.ratings[self].new_rating
      @pro    = true if pro_rating?
      save
    end

  end

end
