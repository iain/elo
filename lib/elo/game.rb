module Elo

	# A Game is a collection of two Elo::Player objects
	# and a result.
	# Once the result is known, it propagates the new
	# ratings to the players.
  class Game

    include Helper

		# The result is the result of the match. It's a nubmer
		# from 0 to 1 from the perspective of player +:one+.
    attr_reader :result

		# The first Elo::Player. The result is in perspecive of
		# this player.
    attr_reader :one

		# The second Elo::Player.
    attr_reader :two

    # Every time a result is set, it tells the Elo::Player
		# objects to update their scores.
    def process_result(result)
      @result = result
      calculate
    end
    alias result= process_result

    def calculate
      if result
        one.send(:played, self)
        two.send(:played, self)
        save
      end
      self
    end

		# Player +:one+ has won!
		# This is a shortcut method for setting the score to 1
    def win
      process_result 1.0
    end

		# Player +:one+ has lost!
		# This is a shortcut method for setting the score to 0
    def lose
      process_result 0.0
    end

		# It was a draw.
		# This is a shortcut method for setting the score to 0.5
    def draw
      process_result 0.5
    end

    # You can override this method if you store each game
		# in a database or something like that.
		# This method will be called when a result is known.
    def save
    end

		# Set the winner. Provide it with a Elo::Player. 
    def winner=(player)
      process_result(player == one ? 1.0 : 0.0)
    end

		# Set the loser. Provide it with a Elo::Player. 
    def loser=(player)
      process_result(player == one ? 0.0 : 1.0)
    end

		# Access the Elo::Rating objects for both players.
    def ratings
      @ratings ||= { one => rating_one, two => rating_two }
    end

    def inspect
      "game"
    end

    private

		# Create an Elo::Rating object for player one
    def rating_one
      Rating.new(:result        => result,
                 :old_rating    => one.rating,
                 :other_rating  => two.rating,
                 :k_factor      => one.k_factor)
    end

		# Create an Elo::Rating object for player two
    def rating_two
      Rating.new(:result        => (1.0 - result),
                 :old_rating    => two.rating,
                 :other_rating  => one.rating,
                 :k_factor      => two.k_factor)
    end

  end

end
