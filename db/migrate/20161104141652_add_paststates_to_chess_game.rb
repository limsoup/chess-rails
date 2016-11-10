class AddPaststatesToChessGame < ActiveRecord::Migration
  def change
  	change_column :chess_games, :movelist, :text, default: [].to_yaml
  	add_column :chess_games, :past_states, :text, default: [].to_yaml
  	add_belongs_to :chess_games, :active_player
  	add_column :chess_games, :game_status, :string, default: "Not Started"
  end
end
