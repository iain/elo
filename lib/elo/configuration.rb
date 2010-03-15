module Elo

  class Configuration

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

    def initialize #:nodoc:
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

    def applied_k_factors #:nodoc:
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

end
