#so this probably doesn't need to be a module of its
#own to give different classes different behaviors.

module ContinueOnPath
	def aggregator
		keep_going = true #self.game.legal?(move) and !self.game.get_piece(move)
		moves = Array.new
		#count = 1
		while keep_going # and count < 5
			move, legal, keep_going = yield
			moves << move if legal
			# puts move.destination.short if move
			# count += 1
		end
		moves
	end
end

module OnceOnPath
	def aggregator
		moves = Array.new
		move, legal, keep_going = yield
		moves << move if legal
		moves
	end
end

