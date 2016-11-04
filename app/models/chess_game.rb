class ChessGame < ActiveRecord::Base
	belongs_to :white_player, class_name: 'User'
	belongs_to :black_player, class_name: 'User'

	scope :accepted, -> {where("white_accept == ? AND black_accept == ?", true, true)}
	# scope :waiting_on, -> user { where("(white_player_id = ? AND white_accept != ?) OR (black_player_id = ? AND black_accept != ?)", user.id, true, user.id, true ) }

	scope :waiting, -> {where("white_accept = ? AND black_accept IS NULL", true)}


	def self.waiting_on(user)
		# puts caller
		# puts self.to_s
		where("(white_player_id == ? AND white_accept IS NULL) OR (black_player_id == ? AND black_accept IS NULL)", user.id, user.id )
		# where("black_player_id == ? AND black_accept IS NULL", user.id )
	end

	def accepted?
		white_accept != nil and black_accept != nil
	end
end
