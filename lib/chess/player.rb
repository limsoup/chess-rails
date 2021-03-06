class Player
	attr_accessor :game, :white, :captures
	def initialize(game, isWhite)
		self.game = game
		self.white = isWhite
		self.captures = isWhite ? game.white_captures : game.black_captures
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