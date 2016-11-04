class AddMovelistToChessGame < ActiveRecord::Migration
  def change
    add_column :chess_games, :movelist, :text
    change_column :chess_games, :fen, :string, default: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
  end
end
