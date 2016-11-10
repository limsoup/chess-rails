# require Matrix
require 'matrix'
# require 'math'
require_dependency './directional'
require_dependency './accumulation'
#initial vectors
#rotate 
#use the class
#push_forward



class Piece
	attr_accessor :initial_vectors, :position, :board, :player #, :has_moved, :piece_id_for_game

	def initialize(player, board, position) #, piece_id_for_game
		self.player = player
		self.board = board
		self.position = position
		# self.has_moved = false
		#self.piece_id_for_game = piece_id_for_game
	end
	

	def printPiece
		self.player.white ? self.class::PrintChar.upcase : self.class::PrintChar
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
	def gather_legal_moves(ignore_king_danger = false)
		moves = super
		if ignore_king_danger == false and board.game.is_check_simulation == false
			#kingside castle
			valid_ksc = true

			targeted_positions = player.opponent.pieces.flat_map do |opponent_piece|
				opponent_piece.gather_legal_moves(true).map do |opponent_move|
					opponent_move.destination
				end
			end
			# if board.game.debug
			# 	puts "kingside"
			# 	puts "board.in_check?: #{board.in_check?(player)}"
			# 	puts "has_moved: #{has_moved}"
			# 	puts "kSRook: #{kSRook}"
			# 	puts "kSRook.has_moved: #{kSRook.has_moved}"
			# end
			if !board.in_check?(player) and (player.white ? board.wkc : board.bkc )
				# kSRook = board.get_piece(Position.new(7,position.file))
				between_pos = position
				[1,2].each do |square|
					between_pos = position.horizontal(1)
					if board.get_piece(between_pos) or targeted_positions.include?(between_pos)
						# if board.game.debug
						# 	puts "board.get_piece(between_pos) #{board.get_piece(between_pos)}"
						# 	puts "targeted_positions.include?(between_pos) #{targeted_positions.include?(between_pos)}"
						# end
						valid_ksc = false 
					end
				end
			else
				valid_qsc = false
			end

			if valid_ksc
				moves << Move.new(self, position.horizontal(2))
			end

			#queenside castle

			# if board.game.debug
			# 	puts "queenside"
			# 	puts "board.in_check?: #{board.in_check?(player)}"
			# 	puts "has_moved: #{has_moved}"
			# 	puts "qSRook: #{qSRook}"
			# 	puts "qSRook.has_moved: #{qSRook.has_moved}"
			# end
			valid_qsc = true
			if !board.in_check?(player) and (player.white ? board.wqc : board.bqc )
				# qSRook = board.get_piece(Position.new(0,position.file))
				[1,2,3].each do |square|
					between_pos = position.horizontal(-1)
					if board.get_piece(between_pos) or targeted_positions.include?(between_pos)

						# if board.game.debug
						# 	puts "board.get_piece(between_pos) #{board.get_piece(between_pos)}"
						# 	puts "targeted_positions.include?(between_pos) #{targeted_positions.include?(between_pos)}"
						# end
						valid_qsc = false
					end
				end
			else
				valid_qsc = false
			end

			if valid_qsc
				moves << Move.new(self, position.horizontal(-2))
			end

		end
		
		moves
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

	def gather_legal_moves(ignore_king_danger = false)
		# return [] if caller.length > 130
		moves = []
		moves << Move.new(self, position.vertical(player.white ? 1 : -1))
		if (position.file == 1 and player.white) or (position.file == 6 and !(player.white))
			moves << Move.new(self, position.vertical(player.white ? 2 : -2))
		end

		
		if(player.white)
			if(board.get_piece(position.vertical(1).horizontal(-1)))
				moves << Move.new(self, position.vertical(1).horizontal(-1))
			end
			if(board.get_piece(position.vertical(1).horizontal(1)))
				moves << Move.new(self, position.vertical(1).horizontal(1))
			end
		else

			if(board.get_piece(position.vertical(-1).horizontal(-1)))
				moves << Move.new(self, position.vertical(-1).horizontal(-1))
			end
			if(board.get_piece(position.vertical(-1).horizontal(1)))
				moves << Move.new(self, position.vertical(-1).horizontal(1))
			end
			# moves << Move.new(self, position.vertical(-1).horizontal(-1))
			# moves << Move.new(self, position.vertical(-1).horizontal(1))
		end

		if board.en_passantable_pawn
			en_passantable_pawn = board.en_passantable_pawn
			if (en_passantable_pawn.position.file == position.file and ((en_passantable_pawn.position.rank - position.rank).abs == 1))
				moves << Move.new(self, en_passantable_pawn.position.vertical(player.white ? 1 : -1) )
			end
		end

		legal_moves = []

		moves.each do |move|
			if board.legal?(move)
				if move.destination.file == 0 or move.destination.file == 7
					promotion_moves = ['q','n','b','r'].map do |c|
						move.promotion = c
					end
					legal_moves = legal_moves.concat promotion_moves
				else
					legal_moves << move
				end
			end
		end
	end
end
