# encoding: utf-8
require 'matrix'
require_dependency './directional'
require_dependency './accumulation'



class Piece
	attr_accessor :initial_vectors, :position, :board, :color

	def initialize(color, board, position) 
		self.color = color
		self.board = board
		self.position = position
	end

	def register_watch_if_in_bounds(current_position)
		if current_position.in_bounds?
			blocker = board.get_piece current_position
			capture = blocker if blocker and blocker.color != color
			board.register_watch({
				can_move: (!!capture or !blocker),
				can_attack: (!!capture or !blocker),
				watcher_position: self.position.short,
				watched_position: current_position.short
			})
		end
	end

	def printPiece
		(self.color == 'white') ? self.class::PrintChar.upcase : self.class::PrintChar
	end

	def calculate
		board.deregister_position position
	end
end


class Priest < Piece
	include Directional::Diagonally
	include OnceOnPath
end

class Outpost < Piece
	include Directional::Straightly
	include OnceOnPath
end


class King < Piece
	include Directional::Straightly
	include Directional::Diagonally
	include OnceOnPath


	PrintChar = 'k'
	def calculate
		super

		#since this gets recalculated for every move, so we don't need to watch everything that could affect it, which would be inefficient anyways
		# moves.reject! do |move|
		# 	get_cell(move.destination)[:watched_by].any? do |watch|
		# 		watch[:watcher_position].color != self.color 
		# 	end
		# end

		#kingside castle
		valid_ksc = true
		if !board.in_check? and (color == "white" ? board.wkc : board.bkc )
			[1,2].each do |square|
				between_pos = position.horizontal(square)
				if (board.get_piece(between_pos) or 
					board.get_cell(position)[:watched_by].any? { |watch| board.get_piece(watch[:watcher_position]).color != self.color and watch[:can_attack] == true  })
					valid_ksc = false 
				end
			end
		else
			valid_ksc = false
		end

		if valid_ksc
			board.register_watch({
				can_move: true,
				can_attack: false,
				watcher_position: position.short,
				watched_position: position.horizontal(2).short
			})
		end

		#queenside castle

		valid_qsc = true
		if !board.in_check? and (color == "white" ? board.wqc : board.bqc )
			[1,2,3].each do |square|
				between_pos = position.horizontal(-1*square)
				if (board.get_piece(between_pos) or 
					board.get_cell(position)[:watched_by].any? { |watch| board.get_piece(watch[:watcher_position]).color != self.color and watch[:can_attack] == true  })
					valid_qsc = false 
				end
			end
		else
			valid_qsc = false
		end

		if valid_qsc
			board.register_watch({
				can_move: true,
				can_attack: false,
				watcher_position: position.short,
				watched_position: position.horizontal(-2).short
			})
		end
	end
end

class Knight < Piece
	include Directional::Knightly
	include OnceOnPath

	PrintChar = 'n'
end

class Bishop < Piece
	include Directional::Diagonally
	include ContinueOnPath

	PrintChar = 'b'
end

class Rook < Piece
	include Directional::Straightly
	include ContinueOnPath

	PrintChar = 'r'
end

class Queen < Piece
	include Directional::Straightly
	include Directional::Diagonally
	include ContinueOnPath

	PrintChar = 'q'
end

class Pawn < Piece
	PrintChar = 'p'

	def register_watch_if_in_bounds(current_position, diag = false)
		if current_position.in_bounds?
			blocker = board.get_piece current_position
			capture = blocker if blocker and blocker.color != color
			watch_obj = {
				can_move: ((!!capture and diag) or (!blocker and !diag)) ,
				can_attack: (!!capture or diag),
				watcher_position: self.position.short,
				watched_position: current_position.short
			}
			if (color == "white" and current_position.file == 7) or (color == "black" and current_position.file == 0)
				"QNRB".split('').each do |pr|
					dup_watch = watch_obj.dup
					dup_watch[:promotion]  = pr
					board.register_watch(dup_watch)
				end
			else
				board.register_watch(watch_obj)
			end
		end
	end


	def calculate
		super
		if color == "white"
			#move forward
			register_watch_if_in_bounds(position.vertical(1))
			register_watch_if_in_bounds(position.vertical(2)) if position.file == 1
			#diagonals
			register_watch_if_in_bounds(position.vertical(1).horizontal(-1), true)
			register_watch_if_in_bounds(position.vertical(1).horizontal(1), true)
			#watch for en passants
			if position.horizontal(1).in_bounds? and position.rank == 4
				board.register_watch({
					can_move: false,
					can_attack: false,
					watcher_position: self.position.short,
					watched_position: position.horizontal(1).short,
					watcher_color: color
				})
			end
			if position.horizontal(-1).in_bounds? and position.rank == 4
				board.register_watch({
					can_move: false,
					can_attack: false,
					watcher_position: self.position.short,
					watched_position: position.horizontal(-1).short,
					watcher_color: color
				})
			end
		else 
			#move forward
			register_watch_if_in_bounds(position.vertical(-1))
			register_watch_if_in_bounds(position.vertical(-2)) if position.file == 6
			#diagonals
			register_watch_if_in_bounds(position.vertical(-1).horizontal(-1), true)
			register_watch_if_in_bounds(position.vertical(-1).horizontal(1), true)
			#watch for en passants
			if position.horizontal(1).in_bounds?  and position.rank == 3
				board.register_watch({
					can_move: false,
					can_attack: false,
					watcher_position: self.position.short,
					watched_position: position.horizontal(1).short,
					watcher_color: color
				})
			end
			if position.horizontal(-1).in_bounds? and position.rank == 3
				board.register_watch({
					can_move: false,
					can_attack: false,
					watcher_position: self.position.short,
					watched_position: position.horizontal(-1).short,
					watcher_color: color
				})
			end
		end

		# puts "board.en_passantable_pawn_position_short"
		# puts board.en_passantable_pawn_position_short
		if board.en_passantable_pawn_position_short and board.get_piece(board.en_passantable_pawn_position_short).color != color
			en_passantable_pawn = board.get_piece(board.en_passantable_pawn_position_short)
			if (en_passantable_pawn.position.file == position.file and ((en_passantable_pawn.position.rank - position.rank).abs == 1))
				board.register_watch({
					can_move: true,
					can_attack: false,
					watcher_position: self.position.short,
					watched_position: en_passantable_pawn.position.vertical(color == "white" ? 1 : -1).short,
					remove_after_en_passant: true,
					watcher_color: color
				})
				board.register_watch({
					can_move: false,
					can_attack: true,
					watcher_position: self.position.short,
					watched_position: en_passantable_pawn.position.short,
					remove_after_en_passant: true,
					watcher_color: color
				})

				# moves << Move.new(self, en_passantable_pawn.position.vertical(color == "white" ? 1 : -1) )
			end
		end

		# legal_moves = []

		# moves.each do |move|
		# 	if board.in_bounds?(points)
		# 		if move.destination.file == 0 or move.destination.file == 7
		# 			promotion_moves = ['q','n','b','r'].map do |c|
		# 				move.promotion = c
		# 			end
		# 			legal_moves << promotion_moves
		# 		else
		# 			legal_moves << move
		# 		end
		# 	end
		# end
	end
end
