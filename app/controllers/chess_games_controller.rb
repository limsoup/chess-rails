require 'socket.io-emitter'

class ChessGamesController < ApplicationController
  before_action :authenticate
  before_action :set_chess_game, only: [:show, :rsvp, :invite, :moves, :do_move, :ping, :reset, :recalculate]
  before_action :is_active_player?, only: [:do_move]


  def index
    @chess_games = ChessGame.all
  end

  def new
    @chess_game = ChessGame.new
    @app_data = app_data
    @current_user_data = current_user_data
    
    render 'spa'
  end

  def show
    @current_user_data = current_user_data
    @app_data = app_data
    render 'spa'
  end



  # ajax

  def create
    @chess_game = ChessGame.new chess_game_params
    @chess_game.rsvp(current_user.id, rsvp_params[:color], rsvp_params[:join] == "true")
    if @chess_game.save
      render_gamestate
    else
      format.json { render json: @chess_game.errors, status: :unprocessable_entity }
    end
  end


  def ping
    render json:@chess_game.ping
  end

  def state
    render_gamestate
  end

  def do_move
    @chess_game.do_move(move_params)
    @chess_game.save
    # render_gamestate
    emit_gamestate
  end


  # def accept
  #   # @chess_game.black_player = current_user.id
  #   # @chess_game.black_accept = game_acceptance_params
  #   respond_to do |format|
  #     if current_user.id == @chess_game.black_player_id #and @chess_game.black_accept == nil
  #       @chess_game.accept
  #       if @chess_game.save
  #         format.html { redirect_to @chess_game, status: :ok, notice: 'Chess game was successfully updated.' }
  #         format.json { render :show, status: :created, location: @chess_game }
  #       else
  #         format.html { render current_user }
  #         format.json { render json: @chess_game.errors, status: :unprocessable_entity }
  #       end
  #     else
  #         format.html { redirect_to current_user  } #, status: 405, notice: "Only the black player may accept/reject a game, and only once per game."
  #         format.json { render json: {message: "Only the black player may accept/reject a game, and only once per game."}, status: 405 }
  #     end
  #   end
  # end

  # def leave

  # end

  def invite
    @chess_game.invite(current_user.id, invite_params[:email])
    @chess_game.save
    # render_gamestate
    emit_gamestate
  end

  def rsvp
    @chess_game.rsvp(current_user.id, rsvp_params[:color], rsvp_params[:join] == "true" )
    @chess_game.save if @chess_game
    # render_gamestate
    emit_gamestate
  end

  # def join
    
  #   @chess_game.join(current_user.id, join_params[:color])
  #   @chess_game.save
  #   render_gamestate
  # end

  # def accept
  #   @chess_game.rsvp(current_user.id, true)
  #   @chess_game.save
  #   render_gamestate
  # end

  # def decline
  #   @chess_game.rsvp(current_user.id, false)
  #   @chess_game.save
  #   render_gamestate
  # end



  # utility requests, not part of actual UX
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

  private

    def current_user_data
      current_user_data = {
        id: current_user.id,
        name: current_user.email
      }
    end

    def app_data
      app_data = {
        id: @chess_game.id,
        status: @chess_game.game_status,
        active_player_id: @chess_game.active_player_id,
        board: {
          fen: @chess_game.board.fen_str,
          movelist: @chess_game.board.movelist,
          moves: @chess_game.board.valid_moves_for_active_color
        }
      }
      
      app_data[:white_player] = { 
        id: @chess_game.white_player_id,
        color: "white",
        captures: @chess_game.board.white_captures
      }
      if @chess_game.white_player
        if current_user and current_user.id == @chess_game.white_player.id
          app_data[:white_player][:name] = "You"
        else
          app_data[:white_player][:name] = @chess_game.white_player.email
        end
        app_data[:white_player][:accepted] = @chess_game.white_accept
      end

      app_data[:black_player] = { 
        id: @chess_game.black_player_id,
        color: "black",
        captures: @chess_game.board.black_captures
      }
      if @chess_game.black_player
        if current_user and current_user.id == @chess_game.black_player.id
          app_data[:black_player][:name] = "You"
        else
          app_data[:black_player][:name] = @chess_game.black_player.email
        end
        app_data[:black_player][:accepted] = @chess_game.black_accept
      end

      app_data
    end

    def set_chess_game
      @chess_game = current_user.games.find(params[:id])
      redirect_to current_user unless @chess_game
    end

    def is_active_player?
      respond_to {|format| format.json {head :no_content} } if @chess_game.active_player.id != current_user.id
    end

    def render_gamestate
      @app_data = app_data
      render json: @app_data
    end

    def emit_gamestate
      @app_data ||= app_data
      emitter = SocketIO::Emitter.new(redis: $redis)
      
      # emitter.emit('join_room', @chess_game.id.to_s)

      # emitter.to(@chess_game.id.to_s).emit('do_update', app_data.to_json)
      emitter.to(@chess_game.id.to_s).emit('do_update', app_data.to_json)
      render :nothing => true 
    end

    def rsvp_params
      params.require(:rsvp).permit(:color, :join)
    end

    def invite_params
      params.require(:invite).permit(:email)
    end

    def move_params
      params.require(:move).permit(:origin, :destination, :promotion)
    end

    def chess_game_params
      params.require(:chess_game).permit(:fen)
    end
end
