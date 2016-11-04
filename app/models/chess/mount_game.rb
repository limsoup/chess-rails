require './game'

# chess_game = ChessGame.new(true, "bishop.txt")
# chess_game.board.print_board
# p = Position.new_short("D5")
# chess_game.board.get_piece(p).gather_legal_moves.each { |e| puts e.destination.short  }

chess_game = ChessGame.new

def parse_move(str)
	start_square, end_square, promo_code= str.split
	start_pos = Position.new_short(start_square)
	end_pos = Position.new_short(end_square)
	[start_pos, end_pos, promo_code]
end

file = File.open('playfile.txt')
play = file.readlines


begin
	i = 0
	while chess_game.end_status.empty? and i < play.length
		input = play[i].chomp
		i += 1
		# gets.chomp
		begin
			start_pos, end_pos, promo_code = parse_move(input)
			move = chess_game.new_move_from_coordinates(start_pos, end_pos, promo_code)
			puts move.class
			chess_game.board.do_move(move)
		rescue Exception => e
			puts e
			puts input
		end
	end
	chess_game.debug = true
	# puts chess_game.game_status
	puts "-----------"
	chess_game.print_active_player_moves
	puts "-----------"
	puts "now go ahead > "
	input = gets.chomp
	start_pos, end_pos, promo_code = parse_move(input)
	move = chess_game.new_move_from_coordinates(start_pos, end_pos, promo_code)
	puts move.class
	chess_game.board.do_move(move)
	puts "-----------"
	chess_game.board.print_board
rescue SystemStackError
  puts $!
  puts caller[0..100]
end
