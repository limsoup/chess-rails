# encoding: utf-8
require_dependency "./move"

module Directional

	Rotate = Matrix[[0, -1],[1, 0]]

	def initialize(*args)
		super
		self.initial_vectors ||= Array.new
	end

	def with_rotations(phase)
		# direction = phase
		# yield(direction)
		[2,3,4,5].each do |i|
			direction = phase*(Rotate**i)
			yield(direction)
		end
	end

	def calculate
		# moves = Array.new
		super
		board.deregister_position position
		initial_vectors.each do |vector_method_name|
			self.send(vector_method_name) do |phase|
				with_rotations(phase) do |direction|
					move = Move.new(self, self.position)
					aggregator(direction)
				end
			end
		end
		# moves
	end


	module Straightly
		# include FourDirections
		# include ContinuousMovement
		# include Matrix
		include Directional
		Phase = Matrix[[0,1]]
		def with_straights
			yield(Phase)
		end

		def initialize(*args)
			super
			self.initial_vectors << :with_straights
		end
	end

	module Diagonally
		# include FourDirections
		# include ContinuousMovement
		# include Matrix
		include Directional
		Phase = Matrix[[1,1]]
		def with_diagonals
			yield(Phase)
		end

		def initialize(*args)
			super
			self.initial_vectors << :with_diagonals
		end
	end

	module Knightly
		# include FourDirections
		# include ContinuousMovement
		# include Matrix
		include Directional
		Phase1 = Matrix[[2,1]]
		Phase2 = Matrix[[2,-1]]
		def with_knight_1
			yield(Phase1)
		end

		def with_knight_2
			yield(Phase2)
		end

		def initialize(*args)
			super
			self.initial_vectors << :with_knight_1
			self.initial_vectors << :with_knight_2
		end
	end
end
