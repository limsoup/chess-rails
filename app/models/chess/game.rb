require './player'
require './board'
require './invalid_move'
require './move'
require './position'

class ChessGame
	attr_accessor :white_game_player, :black_game_player, :board, 
		:active_player, :half_move_counter, :full_move_counter,
		:simulated_game, :end_status, :moves,
		:is_check_simulation #, :debug

		#need as db attributes
		#end_status:string, moves:text, past_states:text 

		#get rid of
		#debug




	def pawn_just_moved_twice
		#returns pawn that just just moved 
		#2 spaces if it did so in the last move
		#otherwise returns nil
		if !moves.empty?
			from, to, promo = Move.move_info_from_short(moves.last)
			right_dist = abs(from.file - to.file) == 2
			moved_piece = get_piece(to)
			is_pawn = moved_piece and moved_piece.is_a?(Pawn)
			(is_pawn and right_dist) ? moved_piece : nil
		else
			nil
		end
	end

	def print_active_player_moves
		board.get_moves_for_active_player.each do |move|
			puts "#{move.piece.class.to_s} at #{move.piece.position.short} to #{move.destination.short} #{move.promotion}"
		end
	end

	def check_status
		moves = board.get_moves_for_active_player
		if half_move_counter > 49 or past_states.count(fen_str) > 2
			end_game("1/2-1/2")
		elsif moves.empty?
			if board.in_check?(active_player.opponent)
				if active_player.white
					end_game("0-1")
				else
					end_game("1-0")
				end
			else
				end_game("1/2-1/2")
			end
		end
	end

	def game_status
		if end_status.empty?
			"expecting a move from the #{active_player.white ? 'white' : 'black'} player"
		else
			"game-ended: #{end_status}"
		end
	end

	def new_move_from_coordinates(init_pos, dest_pos, promotion_code = nil)
		init_pos #= Position.new(rank_1, file_1)
		dest_pos # = Position.new(rank_2, file_2)
		piece = board.get_piece(init_pos)
		#check if there's a piece
		#check if it's the active player's
		throw InvalidMoveError.new if (!piece or !piece.player == self.active_player)
		valid_moves = piece.gather_legal_moves
		#check if it's valid move
		valid_move = valid_moves.find do |move|
			move.destination == dest_pos and promotion_code == move.promotion
		end
		throw InvalidMoveError.new if !valid_move
		valid_move
	end

	def log_move(move, capture, pawn_advance)
		past_states << self.fen_str
		full_move_counter += 1
		if (capture or move.piece.is_a(Pawn))
			half_move_counter = 0
		else
			half_move_counter += 1
		end
		moves << move.short
	end

	def end_game(str)
		end_status = str
	end

	def simulate_move(move)
		self.simulated_game = self.clone
		sim_move = Move.new(self.simulated_game.find_piece(move.piece.piece_id_for_game), move.destination.clone , move.double_pawn_move, move.promotion)
		# puts "self.simulated_game.board.object_id #{self.simulated_game.board.object_id}"
		self.simulated_game.board.do_move(sim_move)
	end

	def rollback_simulate
		self.simulated_game = nil
	end

	def switch_player
		self.active_player = self.active_player.opponent
	end

	def initialize
		self.white_game_player = Player.new(self, true)
		self.black_game_player = Player.new(self, false)
		self.simulated_game = nil
		self.is_check_simulation = false

		fo = {}
		fo[:board_fen], fo[:active_player_fen], fo[:castling_fen], fo[:en_passantable_pawn_fen], fo[:half_move_counter_fen], fo[:full_move_counter]  = self.fen.split
		self.active_player = (fo[:active_player_fen] == 'w') ? self.white_game_player : self.black_game_player
		self.half_move_counter = fo[:half_move_counter_fen].to_i
		self.full_move_counter = fo[:full_move_counter].to_i
		self.board = Board.new(fo)

	end

	def fen_str
		fo = board.fen_obj
		fo[:active_player_fen] = self.active_player.white ? 'w' : 'b'
		fo[:half_move_counter_fen] = self.half_move_counter.to_s
		fo[:full_move_counter_fen] = self.full_move_counter.to_s

		fenstr = fo[:board_fen] + ' ' + fo[:active_player_fen] + ' ' + fo[:castling_fen] + ' ' + fo[:en_passantable_pawn]+ ' ' + fo[:half_move_counter_fen] + ' ' + fo[:full_move_counter_fen]
	end

	def initialize(run_init = true, saved_game_filename = nil)
		if(run_init)
			self.white_game_player = Player.new(self, true)
			self.black_game_player = Player.new(self, false)
			# self.piece_counter = 0
			# layout = nil
			# layout = get_layout(saved_game_filename) if saved_game_filename
			self.board = ChessBoard.new(self, layout)
			# self.moves ||= []
			self.active_player = self.white_game_player
			# self.needs_promotion = false
			self.simulated_game = nil
			self.is_check_simulation = false
			self.end_status = ''
		end
		#create players
		#create board
	end

	def find_piece(piece_id_for_game)
		(self.board.pieces.find { |p| p.piece_id_for_game == piece_id_for_game } ||
			self.black_game_player.captures.find { |m| m.piece.piece_id_for_game = piece_id_for_game } || 
			self.white_game_player.captures.find { |m| m.piece.piece_id_for_game = piece_id_for_game })
	end

	def clone
		ng = ChessGame.new(false)
		ng.piece_counter = 0
		ng.end_status = ''
		ng.needs_promotion = self.needs_promotion ? true : false
		ng.white_game_player = Player.new(ng, true)
		ng.black_game_player = Player.new(ng, false)
		ng.active_player = self.active_player.white ? ng.white_game_player : ng.black_game_player
		ng.board = self.board.clone(ng)
		# puts "ng.board.object_id #{ng.board.object_id}"
		ng.black_game_player.captures, ng.white_game_player.captures = [self.black_game_player.captures, self.white_game_player.captures].map do |player_capture_array|
			player_capture_array.map do |captured_piece|
				captured_piece.class.new(piece.player.white ? ng.white_game_player : ng.white_game_player,
					nb,
					piece.position.clone,
					piece.piece_id_for_game )
			end
		end
		ng.moves = self.moves.map do | move |
			Move.new(ng.find_piece(move.piece.piece_id_for_game),
				move.destination.clone,
				move.double_pawn_move ? true : false,
				move.promotion ? String.new(move.promotion) : nil )
		end
		ng
	end

	def get_layout(saved_game_filename)
		file = File.open(saved_game_filename)
		layout = []
		8.times do
			line = file.gets.chomp
			layout << line
		end
		file.close
		layout
	end
end