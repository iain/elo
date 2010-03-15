module Elo

	# This class calculates the rating between two players,
	# but only from one persons perspective. You need two Rating-instances
	# to calculate ratings for both players. Luckily, Elo::Game handles
	# this for you automatically.
  class Rating

    include Helper

		# The rating of the player you DON"T wish to calculate.
    attr_reader :other_rating

		# The rating of the player you wish to calculate.
    attr_reader :old_rating

		# The k-factor you wish to use for this calculation.
    attr_reader :k_factor

		# The new rating is... wait for it... the new rating!
    def new_rating
      (old_rating.to_f + change).to_i
    end

		private

		# The result of the match. 1 means that the player won, 0 means that the
		# player lost and 0.5 means that it was a draw.
    def result
      raise "Invalid result: #{@result.inspect}" unless valid_result?
      @result.to_f
    end

		# Only values between 0 and 1 are considered to be valid scores.
    def valid_result?
      (0..1).include? @result
    end

		# The expected score is the probably outcome of the match, depending
		# on the difference in rating between the two players.
		# 
		# For more information visit
		# {Wikipedia}[http://en.wikipedia.org/wiki/Elo_rating_system#Mathematical_details]
    def expected
      1.0 / ( 1.0 + ( 10.0 ** ((other_rating.to_f - old_rating.to_f) / 400.0) ) )
    end

		# The change is the points you earn or lose.
		# 
		# For more information visit
		# {Wikipedia}[http://en.wikipedia.org/wiki/Elo_rating_system#Mathematical_details]
    def change
      k_factor.to_f * ( result.to_f - expected )
    end


  end

end
