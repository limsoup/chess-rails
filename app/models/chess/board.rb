require_dependency './pieces'
require_dependency './position'

class ChessBoard
	#maybe I should lock these down?
	attr_accessor :game, :board_array, :en_passantable_pawn, :wqc, :wkc, :bqc, :bkc

	DefaultBoard = ["RNBQKBNR",
		"PPPPPPPP",
		"--------",
		"--------",
		"--------",
		"--------",
		"pppppppp",
		"rnbqkbnr"]
	
	CharToPieceClassnameMap = {
		'R' => Rook,
		'N' => Knight,
		'B' => Bishop,
		'Q' => Queen,
		'K' => King,
		'P' => Pawn
	}

	def get_moves_for_active_game_player
		game.active_game_player.pieces.flat_map do |active_game_player_piece|
			# puts active_game_player_piece
			active_game_player_piece.gather_legal_moves
			# puts rv.length
			# rv
		end
	end

	def initialize(game_object, fen_obj)
		self.game = game_object
		self.board_array = Array.new(8) {Array.new(8)}

		board_fen = fen_obj[:board_fen]
		castling_fen = fen_obj[:castling_fen]

		self.wqc = fen_obj[:castling_fen].include? 'Q'
		self.wkc = fen_obj[:castling_fen].include? 'K'
		self.bqc = fen_obj[:castling_fen].include? 'q'
		self.bkc = fen_obj[:castling_fen].include? 'k'

		if fen_obj[:en_passantable_pawn_fen] != '-'
			self.en_passantable_pawn = get_piece(Position.new_short(fen_obj[:castling_fen]))
		end

		# active_color_fen, castling_fen, en_passant_fen, half_move_clock_fen, move_number_fen = fen_str.split
		board_array_file_fen = board_fen.split('/')
		8.times do |file|
			board_array_cells = board_array_file_fen[file].split(//)
			rank = 0
			board_array_cells.each do |cell|
				if cell.to_i
					num_spaces = cell.to_i
					num_spaces.times do
						self.board_array[file][rank] = nil
						rank += 1
					end
				else
					piece_position = Position.new(rank, file)
					piece_player = /[[:upper:]]/.match(piece_char) ? self.game.white_game_player : self.game.black_game_player
					self.board_array[file][rank] = CharToPieceClassnameMap.new(piece_player, self, currentPosition)
					rank += 1
				end
			end
		end
	end

	def fen_obj
		fo = {}
		fo[:castling_fen] = ''
		fo[:castling_fen] += 'Q' if wqc
		fo[:castling_fen] += 'K' if wkc
		fo[:castling_fen] += 'q' if bqc
		fo[:castling_fen] += 'k' if bkc

		fo[:en_passantable_pawn] = en_passantable_pawn ? en_passantable_pawn.position.short : '-'

		fen_str = Array.new(8) {""}
		board_array.each_with_index do |file, i|
			blank_counter = 0
			file.each do |cell|
				if cell
					if blank_counter > 0
						fen_str[i] += blank_counter.to_s
						blank_counter = 0
					end
					fen_str[i] += cell.printPiece
				else
					blank_counter += 1
				end
			end
		end
		fo[:board_fen] = fen_str.join("/")
		fo
	end

	

	def print_board
		self.board_array.reverse.each do |row|
			row.each do |cell|
				if(cell)
					print cell.printPiece
				else
					print ' '
				end
			end
			print "\n"
		end
	end



	def do_move(move)

		# puts self if !game.is_check_simulation
		# if no moves, stalemate

		# special checks before
		# 	castle
		# 	en passant

		# regular checks before
		# 	capture

		# special actions after
		# 	castle
		# 	en passant
		# 	promotion

		# check if it's in check
		# check for stalemate

		# regular actions after
		# 	capture
		# 	switch active player
		# 	log move


		#needs to be somewhere else
		# check for end of game
		
		# if !game.needs_promotion
			self.en_passantable_pawn = nil
			is_capture = false
			pawn_advance = false
			if move.piece.is_a?(King) and (move.destination.rank - move.piece.position.rank).abs > 1
				change_piece_position(move.piece, move.destination)
				castled_rook = get_piece(Position.new((move.destination.rank < 4) ? 0 : 7, move.destination.file))
				change_piece_position(castled_rook, Position.new(((move.destination.rank < 4) ? 3 : 5), move.destination.file))
				if piece.player.white_game_player
					(move.destination.rank < 4) ? self.wqc = false : self.wkc = false
				else
					(move.destination.rank < 4) ? self.bqc = false : self.bkc = false
				end
			elsif (move.piece.is_a?(Pawn) and 
				(move.destination.rank - move.piece.position.rank).abs > 0 and 
				(move.destination.file - move.piece.position.file).abs > 0 and 
				!get_piece(move.destination))

				change_piece_position(move.piece, move.destination)
				captured_pawn = get_piece(move.destination.vertical(-1*(move.destination.file - move.piece.file)))
				capture(captured_pawn)
				is_capture = true
			else
				if get_piece(move.destination)
					capture(get_piece(move.destination)) 
					is_capture = true
				end
				change_piece_position(move.piece, move.destination)
				pawn_advance = move.piece.is_a?(Pawn)
				if (move.piece.is_a?(Pawn) and (move.destination.file - move.piece.position.file).abs > 1)
					self.en_passantable_pawn = move.piece
				elsif move.promotion
					board_array[move.destination.file][move.destination.rank] = CharToPieceClassnameMap[move.promotion].new(
						game.active_game_player,
						self,
						move.destination)
				end
				# if move.piece.position.file == 0 or move.piece.position.file == 7
				# 	game.switch_player
					# game.needs_promotion = true
				# end
			end
			# puts "hello" if game.is_check_simulation == false
			game.switch_player
			game.log_move(move, is_capture, pawn_advance) if game.is_check_simulation == false
			game.check_status if game.is_check_simulation == false
		# end


		# game.check_status
	end

	def change_piece_position(piece, destination)
		board_array[destination.file][destination.rank] = piece
		board_array[piece.position.file][piece.position.rank] = nil
		piece.position = destination
	end

	def capture(piece)
		piece.player.opponent.captures << piece
		board_array[piece.position.file][piece.position.rank] = nil
	end

	def get_piece(position)
		# if !board_array[position.file]
		# 	puts position.short
		# end
		board_array[position.file][position.rank]
	end

	def legal?(move)
		#assume the move is allowed by the piece
		in_bounds?(move) and !same_team?(move) and !endangers_king?(move)
	end

	def in_bounds?(move)
		move.destination.rank > -1 and move.destination.rank < 8 and move.destination.file > -1 and move.destination.file < 8
	end

	def same_team?(move)
		get_piece move.destination and get_piece(move.destination).player.white == move.piece.player.white
	end

	def pieces
		board_array.flat_map do |row|
			row.select do |piece|
				piece if piece
			end
		end
	end

	def endangers_king?(move)
		game.simulate_move move
		game.simulated_game.is_check_simulation = true
		retval = game.simulated_game.board.in_check?(game.active_game_player.opponent)
		game.rollback_simulate
		retval
	end

	def in_check?(player_in_question)
		return false if game.is_check_simulation
		# print_board
		# puts "-----------"
		#so this assumes that the simulated_move is done, and the player is al
		king = self.pieces.find { |p| p.is_a?(King) and p.player == player_in_question }
		pos = king.position

		targeted_positions = player_in_question.opponent.pieces.flat_map do |opponent_piece|
			opponent_piece.gather_legal_moves(true).map do |opponent_move|
				opponent_move.destination
			end
		end

		targeted_positions.include?(pos)
		# opponent = game.opponent(move.player);
		# pieces(opponent).each { |piece|  
		# 	Move.new( piece, move.player.king.position)
		# 	e.available_moves(e)
		# }

	end

end