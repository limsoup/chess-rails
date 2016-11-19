$(document).on('turbolinks:load', function (){
	if($("#board").length > 0){
		// --- UTILITY ---
		var piece_class_map = {
			"p":"pawn",
			"b":"bishop",
			"n":"knight",
			"r":"rook",
			"k":"king",
			"q":"queen"
		};

		/*
		state:
		 "setting up"
		 "can move"
		 "awaiting promotion"
		 "awaiting move response"
		 "waiting on turn"
		 "waiting on valid moves"
		 "done"
		*/

		function short_position(rank, file){
			return String.fromCharCode(rank+97) + (file+1).toString();
		}

		function piece_class(rep_char) {
			return piece_class_map[rep_char.toLowerCase()];
		}

		function color_class(rep_char) {
			return (rep_char.toUpperCase() == rep_char) ? "white" : "black";
		}

		function make_piece(rep_char) {
			return $("<div class='piece "+piece_class(rep_char)+" " + color_class(rep_char) +"'></div>")
		}

		function parse_fen_obj(fen_str) {
			var fo = {};
			var fen_parts = fen_str.split(" ");
			fo["board"] = fen_parts[0];
			fo["player"] = fen_parts[1];
			return fo;
		}

		game = {};


		game.setup = function (setup_data) {
			game.state = "setting up";
			$(".waiting-indicator").addClass("active");

			var fen = setup_data.fen;
			var fen_obj = parse_fen_obj(fen);
			this.setup_board(fen_obj["board"]);
			this.setup_player(fen_obj["player"],setup_data.active_player_id);
			this.setup_captures(setup_data.white_captures, 'white');
			this.setup_captures(setup_data.black_captures, 'black');
			this.setup_movelist(setup_data.movelist);
			this.set_available_moves(setup_data["moves"]);

			// fen
			// white_captures
			// black_captures
			// movelist
			// game_status


			if(/^[0|1]/.test(setup_data.game_status)){
				this.state = "done";
			}
			else if(this.my_player.id != this.white_player.id && this.my_player.id != this.black_player.id){
				this.state = "observing";
				// kick off long polling?
			}
			else if(this.my_player.id == this.active_player.id) {
				this.state = "can move";
				this.set_available_moves(setup_data.moves);
				// get moves
				// this.get_moves();
			}else{
				this.state = "waiting on turn";
				this.long_polling_timer = setInterval(_.bind(function () {
					this.ping();
				},this), 5000);
			}
			$(".waiting-indicator").removeClass("active");
		};

		game.setup_movelist = function (movelist) {
			var ml = $("#move-list");
			ml.empty();
			for (var i = 0; i < movelist.length; i += 2) {
				var move_row_str = "<div class='move-row'>"
					+"<span class='label'>"
						+ (Math.ceil(i/2.0)+1)
					+"</span>"
					+ "<a class='move' href='#'data-half-move-num='"+i+"'>"
						+ movelist[i]
					+ "</a>"
					+ ( i+1 < movelist.length ? ("<a class='move' href='#'data-half-move-num='"+(i+1)+"'>"
						+ movelist[i+1]
					+ "</a>") : '')
				+"</div>"
				ml.append(move_row_str);
			}
		}
		game.setup_captures = function (captures, color) {
			var captures_cont = $("."+color+" .captures");
			captures_cont.empty();
			for (var i = captures.length - 1; i >= 0; i--) {
				captures_cont.append(make_piece(captures[i]));
			}
		}

		game.do_move = function (move) {
			var do_move_options = {
    			dataType: "json",
    			type: "POST",
				beforeSend: function(){
					this.state = "awaiting move response";
					$(".waiting-indicator").addClass("active");
				},
				success: function (data) {
					this.setup(data);
				},
				error: function (jqXHR, textStatus, errorThrown) {
					$(".waiting-indicator").addClass("active");
					console.log("jqXHR : ");
					console.log(jqXHR);
					console.log("textstatus : ");
					console.log(textStatus);
					console.log("errorThrown :");
					console.log(errorThrown);
					alert("error, check log");
				},
				data: {"move": move}
			};
			do_move_options.error = _.bind(do_move_options.error, this);
			do_move_options.success = _.bind(do_move_options.success, this);
			do_move_options.beforeSend = _.bind(do_move_options.beforeSend, this);
			$.ajax(this.do_moves_url, do_move_options);
		};


		game.capture = function(square){
			var piece = square.querySelector('.piece')[0];
			document.querySelector('.players .'+piece.classList.contains('white') ? 'white' : 'black' +' .captures').appendChild(piece);
		};

		game.setup_player = function (player_fen, active_player_id) {
			this.active_player = {};
			if(player_fen == "w"){
				this.active_player.color = "white";
				this.active_player.id = active_player_id;
				$('.players .white').addClass('active');
				$('.players .black').removeClass('active');
			} else {
				this.active_player.color = "black";
				this.active_player.id = active_player_id;
				$('.players .black').addClass('active');
				$('.players .white').removeClass('active');
			}
		};

		game.ping = function () {
			var ping_options = {
    			dataType : "json",
				beforeSend : function () {
					this.state = "waiting on turn";
					$(".waiting-indicator").addClass("active");
				},
				success: function (data) {
					// debugger;
					if(data.active_player_id != this.active_player.id ){
						if(this.long_polling_timer){
							clearInterval(this.long_polling_timer);
							this.long_polling_timer = null;
						}
						this.get_state(data);
					}
				},
				error: function(jqXHR, textStatus, errorThrown) {
					$(".waiting-indicator").addClass("active");
					console.log("jqXHR : ");
					console.log(jqXHR);
					console.log("textstatus : ");
					console.log(textStatus);
					console.log("errorThrown :");
					console.log(errorThrown);
					alert("error, check log");
				}
			};
			ping_options.error = _.bind(ping_options.error, this);
			ping_options.success = _.bind(ping_options.success, this);
			ping_options.beforeSend = _.bind(ping_options.beforeSend, this);
			$.ajax(this.ping_url, ping_options);
		};

		game.get_state = function () {
			var get_state_options = {
    			dataType : "json",
				beforeSend : function () {
					this.state = "waiting on valid moves";
					$(".waiting-indicator").addClass("active");
				},
				success: function (data) {
					// if(data.fen){
					// 	if(this.long_polling_timer){
					// 		clearInterval(this.long_polling_timer);
					// 		this.long_polling_timer = null;
					// 	}
						this.setup(data);
					// }
				},
				error: function(jqXHR, textStatus, errorThrown) {
					$(".waiting-indicator").addClass("active");
					console.log("jqXHR : ");
					console.log(jqXHR);
					console.log("textstatus : ");
					console.log(textStatus);
					console.log("errorThrown :");
					console.log(errorThrown);
					alert("error, check log");
				}
			};
			get_state_options.error = _.bind(get_state_options.error, this);
			get_state_options.success = _.bind(get_state_options.success, this);
			get_state_options.beforeSend = _.bind(get_state_options.beforeSend, this);
			$.ajax(this.get_game_state_url, get_state_options);
		}
		game.set_available_moves = function (data) {
			this.current_available_moves  = data;
			this.moves_dict = {};
			_.each(this.current_available_moves, _.bind(function (v,k) {
				if(_.isUndefined(this.moves_dict[v["origin"]])){
					this.moves_dict[v["origin"]] = [v["destination"]] ;//[_.pick(v,"destination","promotion")];
				}
				else{
					this.moves_dict[v["origin"]].push(v["destination"]); //_.pick(v,"destination","promotion"));
				}
			},this));

			this.state = "can move"
		};


		game.setup_board = function (board_fen) {
			var board_array_file_fen = board_fen.split('/');
			// if(this.my_player.color == 'black'){
				board_array_file_fen = board_array_file_fen.reverse();
				// console.log(board_array_cells);
			// }
			for (var file = 0; file < 8; file++) {
				var board_array_cells = board_array_file_fen[file].split('');
				
				var rank = 0;
				_.each(board_array_cells, _.bind(function (cell) {
					if( _.isNaN(parseInt(cell))  ) {
						this.board.find("[data-rank="+rank+"][data-file="+file+"]").empty();
						this.board.find("[data-rank="+rank+"][data-file="+file+"]").append(make_piece(cell));
						rank++;
					} else {
						for(var k = 0; k < parseInt(cell); k++){
							this.board.find("[data-rank="+rank+"][data-file="+file+"]").empty();
							rank++;
						}
					}
				},this));
			}
		};

		game.setup_app = function setup_app(app_data) {
			_.extend(this, _.pick(app_data, 'get_game_state_url', 'ping_url', 'do_moves_url', 'white_player', 'black_player', 'my_player'));

			
			if(this.my_player.id == this.white_player.id){
				this.my_player.color = 'white';
			}
			if(this.my_player.id == this.black_player.id){
				this.my_player.color = 'black';
			}
			
			this.board = $("#board");

			this.board_cells = _.map($("#board .row"), function (row) {
				return _.map($(row).find('.cell'), function (cell) {
					return $(cell);
				});
			});
			this.drake = dragula($('.cell').get(), {
				isContainer: function (el) { return el.classList.contains('cell'); },
				moves: _.bind(function (el, source, handle, sibling) { 
					return this.state == "can move" && !( _.isUndefined(this.moves_dict[source.id])); 
				}, this),
				accepts: _.bind(  function (el, target, source, sibling) { 
					return _.contains(this.moves_dict[source.id], target.id); 
				}, this),
				mirrorContainer: $("#board")[0], 
				revertOnSpill: true,
				removeOnSpill: false
			});

			this.drake.on("drop", _.bind(function (el, target, source, sibling) {
				if(target.querySelector('.piece').length == 2){
					this.target(capture);
				}
				if(el.classList.contains('pawn')){
					if(el.classList.contains('white')){
						if(parseInt(target.dataset.file) == 7){
							this.state = "awaiting promotion";
							this.pending_promotion_move  = {
								origin: source.id, //short_position(source.dataset.rank, source.dataset.file),
								destination: target.id, //short_position(target.dataset.rank, target.dataset.file),
								promotion: null
							};
							$(".promotion-window").addClass('active');
							$(".promotion-window .piece").removeClass('black').removeClass('white').addClass(this.active_player.color);
							return 0;
						}
					}else {
						if(parseInt(target.dataset.file) == 0){
							this.state = "awaiting promotion";
							this.pending_promotion_move = {
								origin: source.id,  // short_position(source.dataset.rank, source.dataset.file),
								destination: target.id, // short_position(target.dataset.rank, target.dataset.file),
								promotion: null
							};
							$(".promotion-window").addClass('active');
							return 0;
						}
					}
				}
				this.state = "awaiting response";
				this.do_move({
					origin: source.id, //short_position(source.dataset.rank, source.dataset.file),
					destination: target.id, // short_position(target.dataset.rank, target.dataset.file),
					promotion: null
				});
			},this));

			$(".promotion-window .piece").click(_.bind(function (e) {
				var sending_move = Object.new(this.pending_promotion_move);
				sending_move.promotion = $(e.target).data("promotion");
				this.pending_promotion_move = null;
				this.do_move(sending_move);
			},this));


			this.setup(app_data.game_data);
		};

		game.setup_app(app_data);
	}
});