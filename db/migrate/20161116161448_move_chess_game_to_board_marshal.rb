class MoveChessGameToBoardMarshal < ActiveRecord::Migration
  def change
  	remove_column :chess_games, :movelist
  	remove_column :chess_games, :past_states
  	remove_column :chess_games, :white_captures
  	remove_column :chess_games, :black_captures
  	remove_column :chess_games, :fen
  	add_column :chess_games, :board_marshal, :text
  end
end
