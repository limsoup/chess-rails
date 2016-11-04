class User < ActiveRecord::Base
	has_secure_password

	# has_many(:games, class_name:'ChessGame') do
	# 	def chess_games
	# 		ChessGame.where("black_player_id == ? OR white_player_id == ?", self.id , self.id)
	# 	end
	# end

	def games
		ChessGame.where("black_player_id == ? OR white_player_id == ?", self.id , self.id)
	end
	
	# has_many :chess_games, -> (user) {where("black_player == ? OR white_player == ?", user.id , user.id)}
	# has_many :chess_games_as_white, -> (chess_game) {where("white_player == ?", self.id )}
	# has_many :chess_games_as_black, -> (chess_game) {where("black_player == ?", self.id )}
	# has_many :accepted_chess_games, -> (chess_game) {where("black_player == ?", self.id )}
	# has_many :games_waiting_on_opponent, -> (chess_game) (chess_game) {where("black_player == ? AND black_accepted == ?", self.id , true)}
	# has_many :games_waiting_on_self, -> (chess_game) (chess_game) {where("white_player == ? AND black_accepted == ?", self.id , false)}
	has_many :games_as_white, class_name: 'ChessGame', foreign_key: 'white_player_id' #-> (chess_game) {where("white_player == ?", self.id )}
	has_many :games_as_black, class_name: 'ChessGame', foreign_key: 'black_player_id' # -> (chess_game) {where("black_player == ?", self.id )}
	# scope :games, -> {joins(:games_as_white).merge(:games_as_black)}
	# (joins(:games).
	accepts_nested_attributes_for :games_as_black, :games_as_white
	validates :email, presence: true, uniqueness: {case_sensitive: false}


end