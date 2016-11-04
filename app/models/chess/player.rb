class Player
	attr_accessor :game, :white
	def initialize(game, isWhite)
		self.game = game
		self.white = isWhite
	end

	def opponent
		white ? game.black_game_player : game.white_game_player
	end

	def pieces
		game.board.pieces.select do |piece|
			piece.player == self
		end
	end
end