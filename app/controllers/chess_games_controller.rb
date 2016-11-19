class ChessGamesController < ApplicationController
  before_action :authenticate
  before_action :set_chess_game, only: [:show, :reset, :recalculate, :edit, :update, :destroy, :accept, :moves, :do_move, :game_state, :ping]
  before_action :is_active_player?, only: [:do_move, :moves]
  # before_action :load_game, only: [:show, :do_move, :moves, :game_state]
  # GET /chess_games
  # GET /chess_games.json
  def index
    @chess_games = ChessGame.all
  end

  # GET /chess_games/1
  # GET /chess_games/1.json
  def show
    # @chess_game.refresh_board
    # @chess_game.save
    @app_data = @chess_game.app_data
    @app_data.merge!({
      my_player: {id: current_user.id},
      get_moves_url: moves_chess_game_url(@chess_game),
      get_game_state_url: game_state_chess_game_url(@chess_game),
      ping_url: ping_chess_game_url(@chess_game),
      do_moves_url: do_move_chess_game_url(@chess_game)
    })
  end

  def reset
    @chess_game.refresh_board
    @chess_game.save
    redirect_to @chess_game
  end

  def recalculate
    @chess_game.board.recalculate
    @chess_game.save
    redirect_to @chess_game
  end


  def ping
    respond_to do |format|
      format.json {render json:@chess_game.ping }
    end
  end

  def game_state
    @app_data = @chess_game.game_data
    respond_to do |format|
      format.json {render json:@chess_game.game_data }
    end
  end

  # GET /chess_games/new
  def new
    @chess_game = ChessGame.new
    @users = User.all
  end

  # GET /chess_games/1/edit
  def edit
  end

  # POST /chess_games
  # POST /chess_games.json
  def create
    @chess_game = ChessGame.new chess_game_params
    @chess_game.white_player_id = current_user.id
    @chess_game.white_accept = true

    respond_to do |format|
      if @chess_game.save
        format.html { redirect_to @chess_game, notice: 'Chess game was successfully created.' }
        format.json { render :show, status: :created, location: @chess_game }
      else
        format.html { render :new }
        format.json { render json: @chess_game.errors, status: :unprocessable_entity }
      end
    end
  end



  def moves
    # allow if is active player
    respond_to do |format|
      @moves = @chess_game.get_moves_short
      format.html {render 'moves' }
      format.json {render json: @moves, status: :ok}
    end
  end

  def do_move
    # allow if is active player
    respond_to do |format|
      @chess_game.do_move(move_params)
      @chess_game.save
      format.json {render json:@chess_game.game_data }
    end
  end

  def state
    respond_to do |format|
      @chess_game.do_move(move_params)
      @chess_game.save
      format.json {render json:@chess_game.game_data }
    end
  end

  def accept
    # @chess_game.black_player = current_user.id
    # @chess_game.black_accept = game_acceptance_params
    respond_to do |format|
      if current_user.id == @chess_game.black_player_id #and @chess_game.black_accept == nil
        @chess_game.accept
        if @chess_game.save
          format.html { redirect_to @chess_game, status: :ok, notice: 'Chess game was successfully updated.' }
          format.json { render :show, status: :created, location: @chess_game }
        else
          format.html { render current_user }
          format.json { render json: @chess_game.errors, status: :unprocessable_entity }
        end
      else
          format.html { redirect_to current_user  } #, status: 405, notice: "Only the black player may accept/reject a game, and only once per game."
          format.json { render json: {message: "Only the black player may accept/reject a game, and only once per game."}, status: 405 }
      end
    end
  end

  # PATCH/PUT /chess_games/1
  # PATCH/PUT /chess_games/1.json
  def update
    respond_to do |format|
      if @chess_game.update(chess_game_params)
        format.html { redirect_to @chess_game, notice: 'Chess game was successfully updated.' }
        format.json { render :show, status: :ok, location: @chess_game }
      else
        format.html { render :edit }
        format.json { render json: @chess_game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chess_games/1
  # DELETE /chess_games/1.json
  def destroy
    respond_to do |format|
      if @chess_game.accepted?
        format.html { redirect_to current_user, notice: 'Cannot destroy when game has been accepted by both players.' }
        format.json { render json: {message: "Cannot destroy when game has been accepted by both players"}, status: 405 }
      else
        @chess_game.destroy
        format.html { redirect_to current_user, notice: 'Chess game was successfully destroyed.' }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chess_game
      @chess_game = current_user.games.find(params[:id])
      # @chess_game = ChessGame.find(params[:id])
      redirect_to current_user unless @chess_game
    end

    def is_active_player?
      respond_to {|format| format.json {head :no_content} } if @chess_game.active_player.id != current_user.id
    end

    # def load_game
    #   @chess_game.load_game
    # end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    # def game_acceptance_params
    #   params.require(:black_accept)
    # end
    def move_params
      params.require(:move).permit(:origin, :destination, :promotion)
    end

    def chess_game_params
      params.require(:chess_game).permit(:black_player_id, :fen)
    end
end
