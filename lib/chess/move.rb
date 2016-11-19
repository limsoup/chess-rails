# require_dependency './position'
class Move
	attr_accessor :piece, :destination, :promotion
	def initialize(piece, destination, promotion = nil)
		# throw StandardError.new if !piece
		self.piece = piece
		self.destination = destination
		self.promotion = promotion
	end

	def short
		{origin: piece.position.short,
		 destination: destination.short,
		 promotion: (promotion ? ' '+promotion : nil)}
	end

	def move_info_from_short(str)
		start_square, end_square, promo_code= str.split
		start_pos = Position.new_short(start_square)
		end_pos = Position.new_short(end_square)
		[start_pos, end_pos, promo_code]
	end

end
