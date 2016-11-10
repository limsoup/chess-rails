# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161107202136) do

  create_table "chess_games", force: :cascade do |t|
    t.string   "fen",              default: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    t.integer  "white_player_id"
    t.integer  "black_player_id"
    t.boolean  "white_accept"
    t.boolean  "black_accept"
    t.datetime "created_at",                                                                            null: false
    t.datetime "updated_at",                                                                            null: false
    t.text     "movelist",         default: "--- []\n"
    t.text     "past_states",      default: "--- []\n"
    t.integer  "active_player_id"
    t.string   "game_status",      default: "Not Started"
    t.text     "white_captures",   default: "--- []\n"
    t.text     "black_captures",   default: "--- []\n"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
  end

end
