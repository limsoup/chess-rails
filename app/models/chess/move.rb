require_relative './position'
class Move
	attr_accessor :piece, :destination, :promotion
	def initialize(piece, destination, promotion = nil)
		# throw StandardError.new if !piece
		self.piece = piece
		self.destination = destination
		self.promotion = promotion
	end

	def short
		piece.position.short + ' ' + destination.short + (promotion ? ' '+promotion : '')
	end

	def move_info_from_short(str)
		start_square, end_square, promo_code= str.split
		start_pos = Position.new_short(start_square)
		end_pos = Position.new_short(end_square)
		[start_pos, end_pos, promo_code]
	end
end