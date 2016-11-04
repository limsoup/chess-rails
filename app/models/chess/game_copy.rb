# possible moves
# 	en passant
# 	check
# 	castling

# actually moving
# 	capturing
# 	promotions

class Piece
	attr_accessor :initial_vectors, :position, :board, :player, :has_moved
end

class Move
	attr_accessor :piece, :destination, :double_pawn_move, :promotion
end

class Board
	#objects
	attr_accessor :game
	#array of objects
	attr_accessor :board_array
end

class Player
	#objects
	attr_accessor :game
	#literals
	attr_accessor :white
	#array of objects
	attr_accessor :captures
end

class Game
	#objects
	attr_accessor :white_game_player, :black_game_player, :board
	#array of objects
	attr_accessor :moves
	#literals
	attr_accessor :active_player, :needs_promotion
end
notes = """
		copy game
			[x] needs_promotion - clone
			[x] white_game_player
				white - clone
				game - reference to new game
				captures - *needs board and black_game_player*
			[x] black_game_player
				white - clone
				game - reference to new game
				captures - *needs board and white_game_player*
			[x] active_player - match color
			[x]board
				game - reference to new game
				board_array [pieces]
						initial_vectors - clone
						position - clone
						board - reference to new board
						player - match color
						has moved - clone
			[x]white_game_player, black_game_player
				captures [pieces]
					initial_vectors - clone
					position - clone
					board - reference to new board
					player - match color
					has moved - clone
			[x]moves [piece]
				piece - reference to piece, search by piece_id_for_game in board and captures
				destination - clone
				double_pawn_move - clone
				promotion - clone
		"""