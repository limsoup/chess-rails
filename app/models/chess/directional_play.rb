# require Matrix
require_relative 'matrix'
require_relative './directional'
require_relative './accumulation'
#initial vectors
#rotate 
#use the class
#push_forward



class Piece
	attr_accessor :initial_vectors, :position

	def initialize(x,y)
		position = {:x => x, :y => y}
	end

	# module Directional

	# 	Rotate = Matrix[[0, -1],[1, 0]]

	# 	def initialize
	# 		self.initial_vectors ||= Array.new
	# 	end

	# 	def with_rotations(phase)
	# 		direction = phase
	# 		yield(direction)
	# 		[2,3,4].each do |i|
	# 			direction = phase*(Rotate**i)
	# 			yield(direction)
	# 		end
	# 	end

	# 	def play
	# 		initial_vectors.each do |vector_method_name|
	# 			self.send(vector_method_name) do |phase|
	# 				with_rotations(phase) do |direction|
	# 					puts direction
	# 				end
	# 			end
	# 		end
	# 	end
	# end

	# module Straightly
	# 	# include FourDirections
	# 	# include ContinuousMovement
	# 	# include Matrix
	# 	include Directional
	# 	Phase = Matrix[[0,1]]
	# 	def with_straights
	# 		yield(Phase)
	# 	end

	# 	def initialize
	# 		super
	# 		self.initial_vectors << :with_straights
	# 	end
	# end

	# module Diagonally
	# 	# include FourDirections
	# 	# include ContinuousMovement
	# 	# include Matrix
	# 	include Directional
	# 	Phase = Matrix[[1,1]]
	# 	def with_diagonals
	# 		yield(Phase)
	# 	end

	# 	def initialize
	# 		super
	# 		self.initial_vectors << :with_diagonals
	# 	end
	# end

	# module Knightly
	# 	# include FourDirections
	# 	# include ContinuousMovement
	# 	# include Matrix
	# 	include Directional
	# 	Phase1 = Matrix[[2,1]]
	# 	Phase2 = Matrix[[2,-1]]
	# 	def with_diagonals
	# 		yield(Phase1)
	# 		yield(Phase2)
	# 	end

	# 	def initialize
	# 		super
	# 		self.initial_vectors << :with_diagonals
	# 	end
	# end
end


class Priest < Piece
	include Directional::Diagonally
end

class Outpost < Piece
	include Directional::Straightly

	# def play
	# 	with_straights do |phase|
	# 		phase
	# 	end
	# end
end

class King < Piece
	include Directional::Straightly
	include Directional::Diagonally
end

class Knight < Piece
	include Directional::Knightly
end

myOutpost = Outpost.new(3,4)
puts "myOutpost.play: "
myOutpost.play


myPriest = Priest.new(3,4)
puts "myPriest.play "
myPriest.play

myKing = King.new(3,4)
puts "myKing.play "
myKing.play