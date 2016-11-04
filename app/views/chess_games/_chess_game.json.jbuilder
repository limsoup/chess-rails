json.extract! chess_game, :id, :state_fen, :white_player, :black_player, :white_accept, :black_accept, :created_at, :updated_at
json.url chess_game_url(chess_game, format: :json)