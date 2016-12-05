# encoding: utf-8

# require 'marshal'
require_dependency './chess/board'
require_dependency './chess/invalid_move'
require_dependency './chess/move'
require_dependency './chess/position'

class ChessGame < ActiveRecord::Base
	belongs_to :white_player, class_name: 'User'
	belongs_to :black_player, class_name: 'User'
	belongs_to :active_player, class_name: 'User'

	before_save :update_board_marshal

	scope :accepted, -> {where("white_accept = ? AND black_accept = ?", true, true)}
	scope :waiting, -> {where("white_accept = ? AND black_accept IS NULL", true)}
	
	def self.waiting_on(user)
		where("(white_player_id = ? AND white_accept IS NULL) OR (black_player_id = ? AND black_accept IS NULL)", user.id, user.id )
	end

	def initialize(attributes = {}, options = {})
		super
		board = ChessBoard.new(self, attributes[:fen])
	end

	# Board
	def refresh_board
		@board = ChessBoard.new(self)
		@board.game = self
		self.active_player_id = self.white_player_id
		@board.active_player_color = "white"
	end

	def board
		@board || load_board
	end

	def board=(board_obj)
		@board = board_obj
	end

	def load_board
		if self.board_marshal
			@board = Marshal.load(self.board_marshal)
			@board.game = self
		else
			@board = ChessBoard.new(self)
		end
		@board
	end

	def update_board_marshal
		if @board
			self.board_marshal = Marshal.dump(@board).force_encoding('utf-8')
			# self.board.game = self
		end
	end

	# Used directly by controller
	def get_moves_short
		board.valid_moves_for_active_color
	end

	def ping
		ping_object = {}
	    ping_object[:active_player_id] = self.active_player_id if self.active_player_id
	    ping_object[:game_status] =  self.game_status
	    ping_object[:white_player_id] = self.white_player_id
	    ping_object[:black_player_id] = self.black_player_id
	    ping_object[:white_accept] = self.white_accept
	    ping_object[:black_accept] = self.black_accept
	    ping_object[:id] = self.id
	    #include something about accept, ids
	    ping_object
	end

	def rsvp(current_user_id, color, accept)
		# this lets someone decline a seat to which they're not even 
		# besides that: i don't like how i've done this overall either
		# maybe having seat records and having logic there would be ideal
		# byebug
		if self.game_status === "Not Started"
			if color === "white"
				if (self.white_player_id === nil or self.white_player_id === current_user_id) and current_user_id != self.black_player_id
					self.white_player_id = current_user_id
					self.white_accept = accept 
				end
			elsif color === "black"
				if (self.black_player_id === nil or self.black_player_id === current_user_id) and current_user_id != self.white_player_id
					self.black_player_id = current_user_id
					self.black_accept = accept
				end
			end
			self.after_membership
		end
	end

	# def rsvp(user_id, value)
	# 	if status === "Not Started"
	# 		if user_id === white_player_id
	# 			if white_accept === nil
	# 				white_accept = value
	# 			end
	# 		elsif user_id === black_player_id
	# 			if black_accept === nil
	# 				black_accept = value
	# 			end
	# 		end

	# 		after_membership
	# 	end
	# end

	def invite(inviter_id, invitee_email)
		# it feels weird having inviter id here
		if self.game_status === "Not Started"
			if inviter_id === self.black_player_id
				if self.white_player_id === nil 
					invitee = User.find_by email:invitee_email
					if invitee
						if invitee.id != inviter_id
							self.white_player_id = invitee.id
							self.white_accept = nil
						end
					end
				end
			elsif inviter_id === self.white_player_id
				if self.black_player_id === nil  
					invitee = User.find_by email:invitee_email
					if invitee
						if invitee.id != inviter_id
							self.black_player_id = invitee.id
							self.black_accept = nil
						end
					end
				end
			end
		end
	end


	def after_membership
		if self.white_accept === false or self.white_player_id === nil
			self.white_player_id = nil
			self.white_accept = nil
		end 
		if self.black_accept === false or self.black_player_id === nil
			self.black_player_id = nil
			self.black_player_id = nil
		end

		if accepted?
			self.game_status = "Started"
        	self.active_player_id = white_player_id
		elsif abandoned?
			self.destroy
		end
	end
	
	
	def accepted?
		self.white_accept == true and self.black_accept == true
	end

	def abandoned?
		self.white_player_id === nil and self.black_player_id === nil
	end


	# def join(user_id, color)
	# 	# color shouldn't exactly be needed. there should only be one available
	# 	# regardless, it doesn't seem wise to depend on that exactly
	# 	# maybe if we had a can_join here too? and similar for the other actions
	# 	if status === "Not Started"
	# 		if color === "white"
	# 			if black_player_id !== user_id
	# 				if white_player_id === nil 
	# 					white_player_id = user_id
	# 					white_accept = true
	# 				end
	# 			end
	# 		elsif color === "black"
	# 			if white_player_id !== user_id
	# 				if black_player_id === nil
	# 					black_player_id = user_id
	# 					black_accept = true
	# 				end
	# 			end
	# 		end
	# 		after_membership
	# 	end
	# end

	def do_move(move_params)
		puts move_params
		start_pos, end_pos, promo_code = parse_move(move_params)
		puts "start pos #{start_pos.short}, end pos #{end_pos.short}"
		move = new_move_from_coordinates(start_pos, end_pos, promo_code)
		puts "piece position #{move.piece.position.short}, destination #{move.destination.short}"
		board.do_move(move)
	end

	def game_data
		# fen, white_captures, black_captures, movelist, game_status
		gdo = {
			fen: self.board.fen_str, 
			white_captures: self.board.white_captures,
			black_captures: self.board.black_captures,
			movelist: self.board.movelist,
			game_status: self.game_status,
			moves: self.board.valid_moves_for_active_color,
			cells: self.board.cell_array
		}
		# console
		gdo[:active_player_id] = self.active_player_id if self.active_player_id
		gdo
	end

	def app_data
		ado = {
			game_data: self.game_data,
			white_player: {id: self.white_player_id},
			black_player: {id: self.black_player_id},
		}
		#get_moves_url
		#do_moves_url
		#white_player
		#black_player
		#my_player
		#full game state
	end

	# utility functions used by board or other functions

	def check_status
		#game status
		# "Rejected"
		# "Not Started"
		# "Started"
		# "1-0"
		# "0-1"
		# "1/2-1/2"
		if board.half_move_counter > 49 or board.past_states.count(board.fen_str) > 2
			game_status = "1/2-1/2"
		elsif board.valid_moves_for_active_color.empty?
			if board.in_check?
				if board.active_player_color === "white"
					game_status = "0-1"
				else
					game_status = "1-0"
				end
			else
				game_status = "1/2-1/2"
			end
		end
	end

	def parse_move(move_params)
		start_square = move_params[:origin]
		end_square = move_params[:destination]
		promo_code= move_params[:promotion].blank? ? nil : move_params[:promotion]
		start_pos = Position.new_short(start_square)
		end_pos = Position.new_short(end_square)
		[start_pos, end_pos, promo_code]
	end

	def new_move_from_coordinates(init_pos, dest_pos, promotion_code = nil)
		move = {}
		move["origin"] = init_pos.short
		move["destination"] = dest_pos.short
		move["promotion"]  = promotion_code
		# byebug
		throw InvalidMoveError.new unless self.board.valid_moves_for_active_color.include?(move)
		move = Move.new(self.board.get_piece(init_pos), dest_pos, promotion_code )
		move
	end


end
