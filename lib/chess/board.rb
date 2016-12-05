# encoding: utf-8

require_dependency './pieces'
require_dependency './position'
class ChessBoard
	#maybe I should lock these down?
	attr_accessor :game, :board_array, :cell_array, :valid_moves_for_active_color, #memoization
	:fen_str, :en_passantable_pawn_position_short,:wqc, :wkc, :bqc, :bkc, :active_player_color, :half_move_counter, :full_move_counter, #fen state
	:white_king_position, :black_king_position, #convenience
	:movelist, :white_captures, :black_captures, :past_states #history
	
	CharToPieceClassnameMap = {
		'R' => Rook,
		'N' => Knight,
		'B' => Bishop,
		'Q' => Queen,
		'K' => King,
		'P' => Pawn
	}

	PieceSortOrder = {
		'P' => 1,
		'N' => 2,
		'B' => 3,
		'R' => 4,
		'Q' => 5
	}

	def marshal_dump
		to_dump = {}
		to_dump[:board_array] = @board_array
		to_dump[:cell_array] = @cell_array
		to_dump[:valid_moves_for_active_color] = @valid_moves_for_active_color
		to_dump[:fen_str] = @fen_str
		to_dump[:en_passantable_pawn_position_short] = @en_passantable_pawn_position_short
		to_dump[:wqc] = @wqc
		to_dump[:wkc] = @wkc
		to_dump[:bqc] = @bqc
		to_dump[:bkc] = @bkc
		to_dump[:active_player_color] = @active_player_color
		to_dump[:half_move_counter] = @half_move_counter
		to_dump[:full_move_counter] = @full_move_counter
		to_dump[:white_king_position] = @white_king_position
		to_dump[:black_king_position] = @black_king_position
		to_dump[:movelist] = @movelist
		to_dump[:white_captures] = @white_captures
		to_dump[:black_captures] = @black_captures
		to_dump[:past_states] = @past_states
		to_dump
	end

	def marshal_load to_load
		@board_array = to_load[:board_array]
		@cell_array = to_load[:cell_array]
		@valid_moves_for_active_color = to_load[:valid_moves_for_active_color]
		@fen_str = to_load[:fen_str]
		@en_passantable_pawn_position_short = to_load[:en_passantable_pawn_position_short]
		@wqc = to_load[:wqc]
		@wkc = to_load[:wkc]
		@bqc = to_load[:bqc]
		@bkc = to_load[:bkc]
		@active_player_color = to_load[:active_player_color]
		@half_move_counter = to_load[:half_move_counter]
		@full_move_counter = to_load[:full_move_counter]
		@white_king_position = to_load[:white_king_position]
		@black_king_position = to_load[:black_king_position]
		@movelist = to_load[:movelist]
		@white_captures = to_load[:white_captures]
		@black_captures = to_load[:black_captures]
		@past_states = to_load[:past_states]
	end

	def initialize(game_object, init_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" )
		self.game = game_object

		self.movelist = []
		self.past_states = []
		self.white_captures = []
		self.black_captures = []
		self.fen_str = init_fen || "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

		fo = {}
		fo[:board_fen], fo[:active_player_color_fen], fo[:castling_fen], fo[:en_passantable_pawn_fen], fo[:half_move_counter_fen], fo[:full_move_counter]  = self.fen_str.split
		self.active_player_color = (fo[:active_player_color_fen] == 'w') ? "white" : "black"
		self.half_move_counter = fo[:half_move_counter_fen].to_i
		self.full_move_counter = fo[:full_move_counter].to_i
		self.wqc = fo[:castling_fen].include? 'Q'
		self.wkc = fo[:castling_fen].include? 'K'
		self.bqc = fo[:castling_fen].include? 'q'
		self.bkc = fo[:castling_fen].include? 'k'


		self.board_array = Array.new(8) {Array.new(8)}
		self.cell_array = Array.new(8) {Array.new(8)}

		if fo[:en_passantable_pawn_fen] != '-'
			self.en_passantable_pawn_position_short = fo[:en_passantable_pawn_fen]
		end

		# active_color_fen, castling_fen, en_passant_fen, half_move_clock_fen, move_number_fen = fen_str.split
		board_array_file_fen = fo[:board_fen].split('/').reverse
		8.times do |file|
			board_array_cells = board_array_file_fen[file].split(//)
			rank = 0
			board_array_cells.each do |cell|
				if cell.to_i != 0
					num_spaces = cell.to_i
					num_spaces.times do
						self.board_array[file][rank] = nil
						self.cell_array[file][rank] = {
							:watched_by => [],
							:watching => []
						}
						rank += 1
					end
				else
					self.cell_array[file][rank] = {
						:watched_by => [],
						:watching => []
					}
					piece_position = Position.new(rank, file)
					piece_player = /[[:upper:]]/.match(cell) ? "white" : "black"
					self.board_array[file][rank] = CharToPieceClassnameMap[cell.upcase].new(piece_player, self, piece_position)
					if self.board_array[file][rank].is_a? King
						if piece_player == "white"
							self.white_king_position = piece_position
						else
							self.black_king_position = piece_position
						end
					end
					rank += 1
				end
			end
		end
		#initial calculation
		self.recalculate
	end

	def update_fen
		fo = {}
		fo[:castling_fen] = ''
		fo[:castling_fen] += 'Q' if wqc
		fo[:castling_fen] += 'K' if wkc
		fo[:castling_fen] += 'q' if bqc
		fo[:castling_fen] += 'k' if bkc

		fo[:active_player_color_fen] = self.active_player_color == "white" ? "w" : "b"
		fo[:half_move_counter_fen] = self.half_move_counter.to_s
		fo[:full_move_counter_fen] = self.full_move_counter.to_s

		fo[:en_passantable_pawn_fen] = en_passantable_pawn_position_short ? en_passantable_pawn_position_short : '-'

		board_fen_array = Array.new(8) {""}
		board_array.reverse.each_with_index do |file, i|
			blank_counter = 0
			file.each do |cell|
				if cell
					if blank_counter > 0
						board_fen_array[i] += blank_counter.to_s
						blank_counter = 0
					end
					board_fen_array[i] += cell.printPiece
				else
					blank_counter += 1
				end
			end
			if blank_counter > 0
				board_fen_array[i] += blank_counter.to_s
				blank_counter = 0
			end

		end
		fo[:board_fen] = board_fen_array.join("/")
		# puts fo
		self.fen_str = fo[:board_fen] +' '+ fo[:active_player_color_fen] +' '+ fo[:castling_fen] +' '+ fo[:en_passantable_pawn_fen] +' '+ fo[:half_move_counter_fen] +' '+ fo[:full_move_counter_fen]
		 # = fo.values.join(' ')
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
		self.en_passantable_pawn_position_short = nil
		# need to clear watch
		cell_array.each do |row|
			row.each do |cell|
				cell[:watched_by].delete_if do |watch|
					watch[:remove_after_en_passant]
				end
				cell[:watching].delete_if do |watch|
					watch[:remove_after_en_passant]
				end
			end
		end
		is_capture = false
		pawn_advance = false

		vacated_piece_positions_to_deregister = []
		populated_piece_positions = []
		move_str = ''
		if move.piece.is_a?(King) and (move.destination.rank - move.piece.position.rank).abs > 1
			#castle
			castled_king_position = move.piece.position.dup
			castled_rook_position = Position.new(((move.destination.rank < 4) ? 0 : 7), move.destination.file)
			castled_rook_destination = Position.new(((move.destination.rank < 4) ? 3 : 5), move.destination.file)
			populated_piece_positions = [move.destination.dup, castled_rook_destination.dup]
			set_at(move.destination, move.piece)
			set_at(castled_rook_destination,  get_piece(castled_rook_position))
			vacated_piece_positions_to_deregister = [castled_rook_position.dup, castled_king_position.dup] 

			if move.piece.color == "white"
				self.wqc = false
				self.wkc = false
				self.white_king_position = move.destination
				if move.destination.rank < 4
					move_str = "0-0-0"
				else 
					move_str = "0-0"
				end
			else
				self.bqc = false
				self.bkc = false
				self.black_king_position = move.destination
				if move.destination.rank < 4
					move_str = "0-0-0"
				else 
					move_str = "0-0"
				end
			end
		elsif (move.piece.is_a?(Pawn) and 
			(move.destination.rank - move.piece.position.rank).abs > 0 and 
			(move.destination.file - move.piece.position.file).abs > 0 and 
			!get_piece(move.destination))
			#en passant

			en_passanted_pawn_position = move.destination.vertical((move.piece.color == "white" ? -1 : 1)*(move.destination.file - move.piece.position.file))
			log_capture(get_piece(en_passanted_pawn_position))
			move_str += notation_str_prefix(move.piece, move.destination) + 'x' + move.destination.short + '.p'
			vacated_piece_positions_to_deregister = [move.piece.position.dup, en_passanted_pawn_position.dup]
			populated_piece_positions = [move.destination]

			set_at(move.destination, move.piece)
			set_at(en_passanted_pawn_position, nil)
			is_capture = true
		else
			vacated_piece_positions_to_deregister = [move.piece.position.dup]
			populated_piece_positions = [move.destination.dup] unless move.piece.is_a? King
			move_str += notation_str_prefix(move.piece, move.destination)
			if get_piece(move.destination)
				log_capture(get_piece(move.destination))
				is_capture = true
				move_str += 'x'
			end
			# puts "general destination: #{move.destination.short}"
			# set_at(move.destination, move.piece )
			pawn_advance = move.piece.is_a?(Pawn)
			move_str += move.destination.short
			
			if move.piece.is_a? King
				if move.piece.color == "white"
					self.white_king_position = move.destination
				else
					self.black_king_position = move.destination
				end
			end

			if (move.piece.is_a?(Pawn) and (move.destination.file - move.piece.position.file).abs == 2)
				self.en_passantable_pawn_position_short = move.destination.short
			end
			
			if move.promotion
				promoted_piece = CharToPieceClassnameMap[move.promotion].new(move.piece.color, self, move.destination)
				set_at(move.piece.position, nil )
				set_at(move.destination,promoted_piece)
				move_str += "="+move.promotion
			else
				# puts "piece short before move #{move.piece.position.short}"
				set_at(move.destination,move.piece)
				# puts "piece after move #{move.piece.position.short}"
			end
		end

		# print_board


		switch_player
		log_move(move, is_capture, pawn_advance, move_str) 
		update_fen
		
		vacated_piece_positions_to_deregister.each do |position|
			deregister_position(position)
		end
		to_recalculate = []
		to_recalculate += vacated_piece_positions_to_deregister.flat_map do |watched_position|
			get_cell(watched_position)[:watched_by].map do |watch|
				watch[:watcher_position]
			end
		end

		to_recalculate += populated_piece_positions
		# populated_piece_positions.each { |p| print "#{p} "  }

		# puts "to recalculate"
		to_recalculate += populated_piece_positions.map{ |watched_position|			
			# print "\n"
			# puts "---"
			# puts watched_position.short
			get_cell(watched_position)[:watched_by].map do |watch|
				# print watch[:watcher_position] + " "
				watch[:watcher_position]
			end
		}.flatten(1)
		# print "\n"
		to_recalculate.uniq!
		to_recalculate += (move.piece.color == "white") ? [white_king_position, black_king_position] : [black_king_position, white_king_position]

		to_recalculate.each do |position|
			# puts position if !get_piece(position)
			# puts position.short
			get_piece(position).calculate
		end

		gather_and_update_moves

		game.check_status
	end

	def recalculate
		self.board_array.flatten(1).compact().each_with_index do |piece, i|
			piece.calculate
			if piece.is_a? King
				if piece.color == "white"
					self.white_king_position = piece.position
				else
					self.black_king_position = piece.position
				end
			end
		end
		gather_and_update_moves
	end

	def gather_and_update_moves
		check_watches = in_check_watches
		move_watches = []
		valid_moves_for_active_color = []
		if check_watches.length == 1
			#moves that attack the checker
			king = active_player_color == "white" ? (get_piece white_king_position) : (get_piece black_king_position)
			checker_watch = get_cell(king.position)[:watched_by].select {|watch| watch[:can_attack] }[0] #and get_piece(watch[:watcher_position]).color != active_player_color
			checker_cell = get_cell(checker_watch[:watcher_position])
			attacks_checker_cell = checker_cell[:watched_by].select{|watch| watch[:can_attack] }
			move_watches.concat attacks_checker_cell

			if(checker_watch[:attack_line])
				blocker_positions = checker_cell[:watching].select{ |watch|
					checker_watch[:attack_line] == watch[:attack_line] and watch[:can_attack] }
					.map {|watch| Position.new_short watch[:watched_position]}

				move_watches.concat (blocker_positions.map { |pos|
									get_cell(pos)[:watched_by].select do |watch|
										# puts watch
										watch[:can_move] and get_piece(watch[:watcher_position]).color == active_player_color
									end
								}.flatten(1))
			end

			move_watches.concat(get_cell(king.position)[:watching].select {|watch| watch[:can_move]})
			#moves that get between the checker and the king
			#moves that the king can make
			#if none, checkmate
		elsif check_watches.length > 1
			#moves that the king can make
			king = active_player_color == "white" ? (get_piece white_king_position) : ( get_piece black_king_position)
			move_watches = get_cell(king.position)[:watching].select {|watch| watch[:can_move]}

		else
			#gather them up from the calculation
			move_watches = cell_array.flatten(1).map { |cell|
				cell[:watched_by].select {|watch| watch[:can_move]}
			}.flatten(1)
			# console
		end
		# debugger
		move_watches = move_watches.select do |watch|
			filter_for_pins_and_checks(watch)
		end
		self.valid_moves_for_active_color = move_watches.map {|watch| 
			short = {}
			short["origin"] = watch[:watcher_position]
			short["destination"] = watch[:watched_position]
			short["promotion"] = watch[:promotion]
			short
		}
		# console
	end

	def filter_for_pins_and_checks(watch)
		#gives false if 
		if watch[:can_move] == true and get_piece(watch[:watcher_position]).color == active_player_color
			piece_cell = get_cell watch[:watcher_position]
			piece = get_piece watch[:watcher_position]
			dest = Position.new_short(watch[:watched_position])
			dest_cell = get_cell dest
			if piece.is_a? King
				# the ones that are attacking the king
				destination_is_under_attack = dest_cell[:watched_by].any?  do |dest_attack| 
					is_attacked = dest_attack[:can_attack]
					get_piece(dest_attack[:watcher_position]).color != piece.color if is_attacked
				end
				if !destination_is_under_attack
					checking_watches = piece_cell[:watched_by].select { |w| w[:can_attack] and get_piece(w[:watcher_position]).color != piece.color }
					if checking_watches.empty?
						true
					else
						dest_is_in_any_attack_line = checking_watches.any? do |check_watch| 
							check_watch[:attack_line] and dest.is_between? check_watch[:attack_line]
						end
						!dest_is_in_any_attack_line
					end
				else
					false
				end
			else
				pinning_watches = piece_cell[:watched_by].select { |w| 
					is_attacked = w[:can_attack]
					by_opponent = w[:color] != piece.color if is_attacked
					has_attack_line = w[:attack_line] if by_opponent
					attack_line_ends_with = get_piece(w[:attack_line][1]) if has_attack_line
					a_king  =  get_piece(w[:attack_line][1]).is_a? King if attack_line_ends_with
				}
				if pinning_watches.empty?
					true
				else 
					#assume a piece can only be pinned once anyways
					(dest.is_between? pinning_watches[0][:attack_line])
				end
			end
		else
			false
		end
	end

	def notation_str_prefix(piece, destination)
		prefix = ''
		watched_by = get_cell(destination)[:watched_by]
		watches_with_same_piece_type = watched_by.select { |watch| get_piece(watch[:watcher_position]).class == piece.class and get_piece(watch[:watcher_position]).color == piece.color and watch[:can_move] }
		prefix += piece.printPiece.upcase
		if watches_with_same_piece_type.length == 1
			return prefix
		else
			and_has_same_file = watches_with_same_piece_type.select { |watch| Position.new_short(watch[:watcher_position]).file == piece.position.file  }
			prefix += piece.position.short[0]
			if and_has_same_file.length == 1
				return prefix
			else
				and_has_same_rank = watches_with_same_piece_type.select { |watch| Position.new_short(watch[:watcher_position]).rank == piece.position.rank  }
				prefix.chop!
				prefix += piece.position.short[1]
				if and_has_same_rank.length == 1
					return prefix
				else
					prefix.chop!
					prefix += piece.position.short
					return prefix
				end
			end
		end
	end

	def register_watch(watch)
		get_cell(watch[:watcher_position])[:watching] << watch
		get_cell(watch[:watched_position])[:watched_by] << watch
	end

	def deregister_position(position)
		cell = get_cell(position)
		cell[:watching].each do |watch_to_deregister|
			watched_cell = get_cell(watch_to_deregister[:watched_position])
			watched_cell[:watched_by].delete(watch_to_deregister)
		end
		cell[:watching] = []
	end

	def set_at(destination, piece_to_place = nil)
		if piece_to_place and piece_to_place.position
			board_array[piece_to_place.position.file][piece_to_place.position.rank] = nil
		end
		board_array[destination.file][destination.rank] = piece_to_place
		piece_to_place.position = destination if piece_to_place 
	end

	def get_cell(position)
		position = (position.is_a? Position) ? position : Position.new_short(position)
		cell_array[position.file][position.rank]
	end

	def log_capture(piece)
		p_index = [*(piece.color == 'white' ? black_captures : white_captures ).each_with_index].bsearch{|x, _| PieceSortOrder[piece.printPiece.upcase] < PieceSortOrder[x.upcase]}
		p_index = p_index ? p_index.last : 0
		((piece.color == "white") ? black_captures : white_captures).insert(p_index, piece.printPiece)
	end

	def get_piece(position)
		position = (position.is_a? Position) ? position : Position.new_short(position)
		board_array[position.file][position.rank]
	end

	def legal?(move)
		in_bounds?(move) and !same_team?(move)
	end

	def in_bounds?(move)
		move.destination.rank > -1 and move.destination.rank < 8 and move.destination.file > -1 and move.destination.file < 8
	end

	def same_team?(move)
		get_piece move.destination and get_piece(move.destination).color == move.piece.color
	end

	def in_check_watches
		king = active_player_color == "white" ? get_piece(white_king_position) : get_piece(black_king_position)
		get_cell(king.position)[:watched_by].select { |watch| watch[:can_attack] }
	end

	def in_check?
		in_check_watches.length > 1
	end

	def switch_player
		self.active_player_color = (self.active_player_color == 'white') ? 'black' : 'white'
		if self.game
			self.game.active_player_id = (self.active_player_color == 'white') ? self.game.white_player_id : self.game.black_player_id
		end
	end

	def log_move(move, capture, pawn_advance, move_short)
		self.past_states << self.fen_str
		self.full_move_counter += 1
		if (capture or pawn_advance)
			self.half_move_counter = 0
		else
			self.half_move_counter += 1
		end
		self.movelist << move_short
	end
end