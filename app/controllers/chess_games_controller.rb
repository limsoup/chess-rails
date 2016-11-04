class ChessGamesController < ApplicationController
  before_filter :authenticate
  before_action :set_chess_game, only: [:show, :edit, :update, :destroy, :accept]

  # GET /chess_games
  # GET /chess_games.json
  def index
    @chess_games = ChessGame.all
  end

  # GET /chess_games/1
  # GET /chess_games/1.json
  def show
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

  def accept
    # @chess_game.black_player = current_user.id
    # @chess_game.black_accept = game_acceptance_params
    respond_to do |format|
      if (current_user.id == @chess_game.black_player_id and @chess_game.black_accept == nil)
        @chess_game.black_accept = true
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
      redirect_to new_user_path unless @chess_game
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    # def game_acceptance_params
    #   params.require(:black_accept)
    # end

    def chess_game_params
      params.require(:chess_game).permit(:black_player_id, :fen)
    end
end
