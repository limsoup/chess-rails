class AddCapturesToChessGame < ActiveRecord::Migration
  def change
    add_column :chess_games, :white_captures, :text, default: [].to_yaml
    add_column :chess_games, :black_captures, :text, default: [].to_yaml
  end
end
