require_dependency './chess/player'
require_dependency './chess/board'
require_dependency './chess/invalid_move'
require_dependency './chess/move'
require_dependency './chess/position'
class ChessGame < ActiveRecord::Base
	attr_accessor :white_game_player, :black_game_player, :board, 
		:active_game_player, :half_move_counter, :full_move_counter,
		:simulated_game, :is_check_simulation

	belongs_to :white_player, class_name: 'User'
	belongs_to :black_player, class_name: 'User'
	belongs_to :active_player, class_name: 'User'

	#game status
	# "Rejected"
	# "Not Started"
	# "Started"
	# "1-0"
	# "0-1"
	# "1/2-1/2"


	before_save :update_fen
	# after_initialize :load_game

	def load_game
		self.white_game_player = Player.new(self, true)
		self.black_game_player = Player.new(self, false)
		self.simulated_game = nil
		self.is_check_simulation = false

		fo = {}
		fo[:board_fen], fo[:active_game_player_fen], fo[:castling_fen], fo[:en_passantable_pawn_fen], fo[:half_move_counter_fen], fo[:full_move_counter]  = self.fen.split
		self.active_game_player = (fo[:active_game_player_fen] == 'w') ? self.white_game_player : self.black_game_player
		self.half_move_counter = fo[:half_move_counter_fen].to_i
		self.full_move_counter = fo[:full_move_counter].to_i
		self.board = ChessBoard.new(self,fo)
	end

	serialize :movelist, Array
	serialize :white_captures, Array
	serialize :black_captures, Array
	serialize :past_states, Array

	scope :accepted, -> {where("white_accept == ? AND black_accept == ?", true, true)}
	# scope :waiting_on, -> user { where("(white_player_id = ? AND white_accept != ?) OR (black_player_id = ? AND black_accept != ?)", user.id, true, user.id, true ) }

	scope :waiting, -> {where("white_accept = ? AND black_accept IS NULL", true)}


	def self.waiting_on(user)
		# puts caller
		# puts self.to_s
		where("(white_player_id == ? AND white_accept IS NULL) OR (black_player_id == ? AND black_accept IS NULL)", user.id, user.id )
		# where("black_player_id == ? AND black_accept IS NULL", user.id )
	end

	def accepted?
		white_accept == true and black_accept == true
	end

	def update_fen
		if self.board
			self.fen = self.fen_str
		end
	end

	def accept
		self.black_accept = true
        # self.active_player = self.white_player
        self.game_status = "Started"
	end

	def get_moves_short
		# byebug
		current_get_moves = self.board.get_moves_for_active_game_player
		if current_get_moves
			current_get_moves.map { |m| m.short  }
		else
			[]
		end
	end

	def ping
		ping_object = {}
	    ping_object[:active_player_id] = self.active_player_id if self.active_player_id
	    ping_object[:game_status] =  self.game_status
	    ping_object
	end

	def game_data
		# fen, white_captures, black_captures, movelist, game_status
		gdo = {
			fen: self.fen, 
			white_captures: self.white_captures.map { |p| p  },
			black_captures: self.black_captures.map { |p| p  },
			movelist: self.movelist,
			game_status: self.game_status,
			moves: self.get_moves_short
		}
		gdo[:active_player_id] = self.active_player_id if self.active_player_id?
		gdo
	end

	def app_data
		ado = {
			game_data: self.game_data,
			white_player: {id: self.white_player.id},
			black_player: {id: self.black_player.id},
		}
		#get_moves_url
		#do_moves_url
		#white_player
		#black_player
		#my_player
		#full game state
	end

	def check_status
		moves = board.get_moves_for_active_game_player
		if half_move_counter > 49 or past_states.count(fen_str) > 2
			game_status = "1/2-1/2"
		elsif moves.empty?
			if board.in_check?(active_game_player.opponent)
				if active_game_player.white
					game_status = "0-1"
				else
					game_status = "1-0"
				end
			else
				game_status = "1/2-1/2"
			end
		end
	end

	def parse_move(move_params)
		start_square = move_params[:origin]
		end_square = move_params[:destination]
		promo_code= move_params[:promotion]
		start_pos = Position.new_short(start_square)
		# puts start_square
		# puts start_pos.short
		end_pos = Position.new_short(end_square)
		# puts end_square
		# puts end_pos.short
		[start_pos, end_pos, promo_code]
	end

	def do_move(move_params)
		start_pos, end_pos, promo_code = parse_move(move_params)
		move = new_move_from_coordinates(start_pos, end_pos, promo_code)
		# puts move.piece
		board.do_move(move)
	end

	def new_move_from_coordinates(init_pos, dest_pos, promotion_code = nil)
		#init_pos #= Position.new(rank_1, file_1)
		#dest_pos # = Position.new(rank_2, file_2)
		piece = board.get_piece(init_pos)
		#check if there's a piece
		#check if it's the active player's
		# puts 'valid?'
		# puts init_pos.short
		# puts dest_pos.short
		# puts piece.printPiece
		# puts piece.player.white
		# puts piece.active_game_player.white
		throw InvalidMoveError.new if (!piece or !piece.player == self.active_game_player)
		valid_moves = piece.gather_legal_moves
		# puts valid_moves.length
		#check if it's valid move
		valid_move = valid_moves.find do |move|
			move.destination == dest_pos and move.promotion == move.promotion
		end
		throw InvalidMoveError.new if !valid_move
		# puts valid_move.piece
		valid_move
	end

	def log_move(move, capture, pawn_advance, move_short)
		self.past_states << self.fen_str
		self.full_move_counter += 1
		if (capture or move.piece.is_a?(Pawn))
			self.half_move_counter = 0
		else
			self.half_move_counter += 1
		end
		self.movelist << move_short
	end

	def simulate_move(move)
		fen_copy = self.fen.dup
		puts fen_copy
		self.simulated_game = ChessGame.new({fen: self.fen.dup})
		self.simulated_game.load_game
		self.simulated_game.is_check_simulation = true
		# debugger
		# puts "self.object_id: #{self.object_id}"
		# puts "self.board.object_id: #{self.board.object_id}"
		# self.simulated_game.is_check_simulation = true
		sim_move = Move.new(self.simulated_game.board.get_piece(move.piece.position.clone), move.destination.clone, move.promotion)
		# puts "move.piece.position"
		# puts move.piece.position.short
		# puts "move.destination.short"
		# puts move.destination.short
		# puts "self.simulated_game.board.object_id #{self.simulated_game.board.object_id}"
		self.simulated_game.board.do_move(sim_move)
	end

	def rollback_simulate
		self.simulated_game = nil
	end

	def switch_player
		self.active_game_player = self.active_game_player.opponent
		self.active_player = self.active_game_player.white ? self.white_player : self.black_player
	end

	# def initialize(attributes = nil, options = {})
	# 	super 
		
	# end

	def fen_str
		fo = self.board.fen_obj
		fo[:active_game_player_fen] = self.active_game_player.white ? 'w' : 'b'
		fo[:half_move_counter_fen] = self.half_move_counter.to_s
		fo[:full_move_counter_fen] = self.full_move_counter.to_s

		fenstr = fo[:board_fen] + ' ' + fo[:active_game_player_fen] + ' ' + fo[:castling_fen] + ' ' + fo[:en_passantable_pawn]+ ' ' + fo[:half_move_counter_fen] + ' ' + fo[:full_move_counter_fen]
		fenstr
	end
end
