class CreateChessGames < ActiveRecord::Migration
  def change
    create_table :chess_games do |t|
      t.string :fen
      t.belongs_to :white_player
      t.belongs_to :black_player
      t.boolean :white_accept
      t.boolean :black_accept

      t.timestamps null: false
    end
  end
end
