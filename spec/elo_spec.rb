require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Elo" do

  after do
    Elo.instance_eval { @config = nil }
  end

  it "should work as advertised" do

    bob  = Elo::Player.new
    jane = Elo::Player.new(:rating => 1500)

    game1 = bob.wins_from(jane)
    game2 = bob.loses_from(jane)
    game3 = bob.plays_draw(jane)

    game4 = bob.versus(jane)
    game4.winner = jane

    game5 = bob.versus(jane)
    game5.loser = jane

    game6 = bob.versus(jane)
    game6.draw

    game7 = bob.versus(jane)
    game7.result = 1

    game8 = bob.versus(jane, :result => 0)

    bob.rating.should == 1080
    jane.rating.should == 1412
    bob.should_not be_pro
    bob.should be_starter
    bob.games_played.should == 8
    bob.games.should == [ game1, game2, game3, game4, game5, game6, game7, game8 ]

    Elo::Player.all.should == [ bob, jane ]
    Elo::Game.all.should == [ game1, game2, game3, game4, game5, game6, game7, game8 ]

  end

  describe "Configuration" do

    it "default_rating" do
      Elo.config.default_rating.should == 1000
      Elo::Player.new.rating.should    == 1000

      Elo.config.default_rating = 1337

      Elo.config.default_rating.should == 1337
      Elo::Player.new.rating.should    == 1337
    end

    it "starter_boundry" do
      Elo.config.starter_boundry.should == 30
      Elo::Player.new(:games_played => 20).should be_starter

      Elo.config.starter_boundry = 15

      Elo.config.starter_boundry.should == 15
      Elo::Player.new(:games_played => 20).should_not be_starter
    end

    it "default_k_factor and FIDE settings" do
      Elo.config.use_FIDE_settings.should    == true
      Elo.config.default_k_factor.should     == 15

      Elo.config.default_k_factor = 20
      Elo.config.use_FIDE_settings = false

      Elo.config.default_k_factor.should     == 20
      Elo.config.use_FIDE_settings.should    == false
      Elo::Player.new.k_factor.should == 20
    end

    it "pro_rating_boundry" do
      Elo.config.pro_rating_boundry.should == 2400

      Elo.config.pro_rating_boundry = 1337

      Elo.config.pro_rating_boundry.should == 1337
      Elo::Player.new(:rating => 1337).should be_pro_rating
    end

  end

  describe "according to FIDE" do

    it "starter" do
      player = Elo::Player.new
      player.k_factor.should == 25
      player.should be_starter
      player.should_not be_pro
      player.should_not be_pro_rating
    end

    it "normal" do
      player = Elo::Player.new(:rating => 2399, :games_played => 30)
      player.k_factor.should == 15
      player.should_not be_starter
      player.should_not be_pro
      player.should_not be_pro_rating
    end

    it "pro rating" do
      player = Elo::Player.new(:rating => 2400)
      player.k_factor.should == 10
      player.should be_starter
      player.should be_pro_rating
      player.should_not be_pro
    end

    it "historically a pro" do
      player = Elo::Player.new(:rating => 2399, :pro => true)
      player.k_factor.should == 10
      player.should be_starter
      player.should_not be_pro_rating
      player.should be_pro
    end
  end

  describe "examples for calculating rating correctly" do

    # examples from http://chesselo.com/

    before do
      @a = Elo::Player.new(:rating => 2000, :k_factor => 10)
      @b = Elo::Player.new(:rating => 1900, :k_factor => 10)
    end

    it "winning" do
      @a.wins_from(@b)
      @a.rating.should == 2003
    end

    it "losing" do
      @a.loses_from(@b)
      @a.rating.should == 1993
    end

    it "draw" do
      @a.plays_draw(@b)
      @a.rating.should == 1998
    end

  end

end
