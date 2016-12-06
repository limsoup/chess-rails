$(document).on('turbolinks:load', function (){
	_.templateSettings = {
	    interpolate: /\<\@\=(.+?)\@\>/gim,
	    evaluate: /\<\@(.+?)\@\>/gim,
	    escape: /\<\@\-(.+?)\@\>/gim
	};

	if($("#chess_game").length > 0){
		var piece_class_map = {
			"p":"pawn",
			"b":"bishop",
			"n":"knight",
			"r":"rook",
			"k":"king",
			"q":"queen"
			};

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


		var User = function () {
			_.extend(this, Backbone.Events);
			return this;	};
		User.prototype.load = function(data) {
			this.id = data.id;
			this.name = data.name	};
		User.prototype.is_invited_player = function () {
			if(this.player()){
				return this.player.is_invited();
			}
			return false;	};
		User.prototype.is_active_player = function (){
			return this.id && this.id === game.active_player_id;
				};
		User.prototype.player = function () {
			if(game.white_player.id == this.id){
				return game.white_player;
			}else if(game.black_player.id == this.id){
				return game.black_player;
			}
			return null;	};


		var Player = function (color) {
			_.extend(this, Backbone.Events);
			this.color = color;
			this.$el = $(".player."+color);
			this.$el.on("keyup", ".invite", _.bind(this.invite,this));
			this.$el.on("click", ".accept", _.bind(this.join,this));
			this.$el.on("click", ".decline", _.bind(this.leave,this));
			this.$el.on("click", ".join", _.bind(this.join,this));
			this.$el.on("click", ".leave", _.bind(this.leave,this));
			this.$el.on("click", ".create_and_join", _.bind(this.create_and_join,this));
			return this;	};
		Player.prototype.template = _.template($("#player-template").html());
		Player.prototype.load = function(data) {
			this.color = data.color;
			this.accepted = data.accepted;
			this.id =	data.id;
			this.name = data.name;
			this.captures = data.captures;
			this.render();	};
		Player.prototype.opponent = function () {
			if(this.color == "white"){
				return game.black_player;
			}else{
				return game.white_player;
			}
			return null;	};
		Player.prototype.is_invited = function () {
			return _.isNumber(this.id)
				&& this.accepted === null; };
		Player.prototype.is_current_user = function () {
			return _.isNumber(this.id) &&
				this.id === game.current_user.id; };
		Player.prototype.can_move = function () {
			return this.id && game.active_player_id && game.active_player_id == this.id;
		};
		Player.prototype.can_be_invited = function () {
			return (game.status == 'Not Started' && 
				game.current_user.player() &&
				this.opponent().is_current_user()) &&
				!this.id;	};
		Player.prototype.can_leave = function () {
			return (game.status == 'Not Started' && 
				this.is_current_user() &&
				// game.current_user.player() &&
				game.current_user.player().accepted === true);	}
		Player.prototype.can_accept_or_decline = function () {
			return this.is_current_user() 
				&& this.is_invited();	};
		Player.prototype.can_create_and_join = function () {
			return !this.id 
				&& !game.id
				&& game.current_user.player() == null;	};
		Player.prototype.can_join = function () {
			return !this.id 
				&& game.current_user.player() == null;	};
		Player.prototype.join = function (e) {
			game.update_request('rsvp', {
				rsvp: {
					color: this.color,
					join: true
				}
			}, 'POST');
				};
		Player.prototype.leave = function (e) {
			game.update_request('rsvp', {
				rsvp: {
					color: this.color,
					join: false
				}
			}, 'POST');
				};
		Player.prototype.invite = function (e) {
			var code = e.keyCode || e.which;
			console.log('inviting');
			if(code == 13){
				game.update_request('invite', { 
					invite : {
						email: this.$el.find('.invite').val(),
						color: this.color
					}
				}, 'POST');
			}
			return e;
			};
		Player.prototype.create_and_join = function (e) {
			game.board_state.compile_fen();
			game.update_request(null, {
				chess_game: {
					fen_str: game.board_state.fen
				},
				rsvp: {
					color: this.color,
					join: true
				}
			}, 'POST')
				.success(_.bind(game.load, game))
				.error(_.bind(game.log_ajax_error, game));
				};
		Player.prototype.renderJSON = function () {
			var retObj = {
				id : this.id,
				color : this.color,
				accepted : this.accepted,
				name : this.name,
				captures: _.map(this.captures, function (c) {
					return {color: color_class(c), piece: piece_class(c)};
				}),
				can_move: this.can_move(),
				can_accept_or_decline : this.can_accept_or_decline(),
				can_join : this.can_join(),
				can_create_and_join : this.can_create_and_join(),
				can_be_invited : this.can_be_invited(),
				can_leave : this.can_leave()
			};
			return retObj;	};
		Player.prototype.render = function() {
			this.$el.empty();
			// console.log(this.renderJSON());
			this.$el.append(this.template(this.renderJSON()));	};


		var BoardState = function () {
			_.extend(this, Backbone.Events);
			this.board = $("#board");
			$("#clear-pieces").click(_.bind(this.clear_pieces,this));
			return this;	};
		BoardState.prototype.movelist_template = _.template($("#movelist-template").html());
		BoardState.prototype.clear_pieces = function (e) {
			e.preventDefault();
			this.board.find('.piece:not(.king)').remove();
			return false;	}
		BoardState.prototype.load = function(data) {
			this.fen = data.fen;
			this.movelist = data.movelist;
			this.moves = data.moves;
			this.setup_move_dict();
			this.render();

			if(!game.id){
				if(!this.insert_drake){
					this.setup_insert_drake();
				}
			}else{
				if(this.insert_drake){
					this.insert_drake.destroy();
				}
			}

			if(game.status == "Started"){
				if(!this.move_drake){
					this.setup_move_drake();
				}
			}else{
				if(this.move_drake){
					this.move_drake.destroy();
				}
			}
				};
		BoardState.prototype.setup_move_dict = function (e) {
			this.moves_dict = {};
			_.each(this.moves, _.bind(function (v,k) {
				if(_.isUndefined(this.moves_dict[v["origin"]])){
					this.moves_dict[v["origin"]] = [v["destination"]] ;//[_.pick(v,"destination","promotion")];
				}
				else{
					this.moves_dict[v["origin"]].push(v["destination"]); //_.pick(v,"destination","promotion"));
				}
			},this));
				}
		BoardState.prototype.render = function(){
			var ml = $("#movelist");
			ml.empty();
			ml.append(this.movelist_template({movelist: this.movelist}));

			var rows = this.fen.split(" ")[0].split('/').reverse();
			// if(game.current_user.player() && game.current_user.player().color == 'black'){
			// 	rows = rows.reverse();
			// }
			for (var file = 0; file < 8; file++) {
				var squares = rows[file].split('');
				
				var rank = 0;
				_.each(squares, _.bind(function (cell) {
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
			}	};
		BoardState.prototype.compile_fen = function () {
			var fo = {}
			fo["castling_fen"] = '';
			if($("#wqc").prop("checked")) {
				fo["castling_fen"] += 'Q'
			}
			if($("#wkc").prop("checked")) {
				fo["castling_fen"] += 'K'
			}
			if($("#bqc").prop("checked")) {
				fo["castling_fen"] += 'q'
			}
			if($("#bkc").prop("checked")) {
				fo["castling_fen"] += 'k'
			}

			fo["active_player_color_fen"] = $("[name=active_color]").val();
			fo["half_move_counter_fen"] = $("#half_moves").val().toString();
			fo["full_move_counter_fen"] = "0"

			fo["en_passantable_pawn_fen"] = $("#en_passantable").val() ? $("#en_passantable").val() : '-'

			var board_fen_array = ["","","","","","","",""];

			_.each(this.board.find(".row"), function (row,i) {
				var blank_counter = 0;
				var row_str = "";
				_.each($(row).find('.cell'), function (cell,j) {
					var c = $(cell);
					if(c.find('.piece').length > 0) {
						var p = $(c.find('.piece'));
						if(blank_counter > 0){
							row_str += blank_counter.toString();
							blank_counter = 0;
						}
						var ch;
						if(p.is('.pawn')){
							ch = "P";
						} else if(p.is('.knight')){
							ch = "N";
						} else if(p.is('.bishop')){
							ch = "B";
						} else if(p.is('.rook')){
							ch = "R";
						} else if(p.is('.king')){
							ch = "K";
						} else if(p.is('.queen')){
							ch = "Q";
						}

						if(p.is('.black')){
							ch = ch.toLowerCase();
						}
						row_str += ch;
					}else{
						blank_counter += 1;
					}
				});
				if (blank_counter > 0){
					row_str += blank_counter.toString();
				}
				if(game.black_player.is_current_user()){
					board_fen_array[i] = _.reverse(row_str);
				} else {
					board_fen_array[i] = row_str;
				}
			});
			if(game.black_player.is_current_user()){
				board_fen_array = _.reverse(board_fen_array);
			}
			fo["board_fen"] = board_fen_array.join("/")
			this.fen = fo["board_fen"] +' '+ fo["active_player_color_fen"] +' '+ fo["castling_fen"] +' '+ fo["en_passantable_pawn_fen"] +' '+ fo["half_move_counter_fen"] +' '+ fo["full_move_counter_fen"];
				};		
		BoardState.prototype.setup_insert_drake = function () {
			this.insert_drake = dragula($('.cell').get(), {
				isContainer: function (el) { return el.classList.contains('cell'); },
				moves: function (el, source, handle, sibling) { 
					return el.classList.contains('piece');
				},
				accepts: function (el, target, source, sibling) { 
					return $(target).is('.row > div') ; 
				},
				mirrorContainer: $("#chess_game")[0],
				copy: function (el, source) {
					return source.classList.contains('edit-piece-cell');
				},
				revertOnSpill: true,
				removeOnSpill: false
			});
			this.insert_drake.on('cancel', function(el, container, source){
				if($(source).is(".row > div") && !el.classList.contains('king')){
					this.remove(el);
				}
			});
				}
		BoardState.prototype.setup_move_drake = function () {
			this.move_drake = dragula($('.cell').get(), {
				isContainer: function (el) { return el.classList.contains('cell'); },
				moves: _.bind(function (el, source, handle, sibling) {
					// console.log('moving') ;
					return (game.current_user.is_active_player() &&
						!( _.isUndefined(this.moves_dict[source.id]))); 
				}, this),
				accepts: _.bind(  function (el, target, source, sibling) { 
					return _.contains(this.moves_dict[source.id], target.id); 
				}, this),
				mirrorContainer: $("#board")[0], 
				revertOnSpill: true,
				removeOnSpill: false
			});

			this.move_drake.on("drop", _.bind(function (el, target, source, sibling) {
				// handle capture
				// if(target.querySelector('.piece').length > 1){
				// 	var skip = 0;
				// 	for (var i = target.children.length - 1; i >= 0; i--) {
				// 		if(el !== target.children[skip]){
				// 			target.removeChild(target.children[skip]);
				// 		}else{
				// 			skip++;
				// 		}
				// 	}
				// }
				// handle promotion
				if(el.classList.contains('pawn')){
					if(el.classList.contains('white')){
						if(parseInt(target.dataset.file) === 7){
							this.pending_promotion_move  = {
								origin: source.id,
								destination: target.id,
								promotion: null
							};
							$(".promotion-window").addClass('active');
							$(".promotion-window .piece").removeClass('black').addClass('white');
							$(".promotion-window .piece").one('click', _.bind(this.complete_promotion_move,this));
							return false;
						}
					}else {
						if(parseInt(target.dataset.file) === 0){
							this.pending_promotion_move = {
								origin: source.id,
								destination: target.id,
								promotion: null
							};
							$(".promotion-window").addClass('active');
							$(".promotion-window .piece").removeClass('white').addClass('black');
							$(".promotion-window .piece").one('click', _.bind(this.complete_promotion_move,this));
							return false;
						}
					}
				}
				game.do_move({ move: {
					origin: source.id, 
					destination: target.id,
					promotion: null
				}});
			},this));
				}
		BoardState.prototype.complete_promotion_move = function (e) {
			console.log('complete promotion move');
			$(".promotion-window").removeClass('active');
			this.pending_promotion_move.promotion = e.target.dataset.promotion;
			var promo_move = _.extend({},this.pending_promotion_move);
			this.pending_promotion_move = undefined;
			game.do_move({move: promo_move});
				};

		var Game = function (user_data) {
			_.extend(this, Backbone.Events);

			this.init_render();
			this.board_state = new BoardState();
			this.white_player = new Player("white");
			this.black_player = new Player("black");
			this.current_user = new User();
			this.current_user.load(user_data);
			return this;	};
		Game.prototype.template = _.template($("#game-template").html());
		Game.prototype.board_template = _.template($("#board-template").html());
		Game.prototype.init_render = function() {
			var renderJSON = this.attributes();
			// renderJSON.player_color = this.black_player && this.black_player.is_current_user() ? "black" : "white";
			$("#chess_game").append(this.template(renderJSON)); };
		Game.prototype.do_move = function (move_obj) {
			this.update_request('do_move', move_obj, 'POST');
				}
		Game.prototype.log_ajax_error = function (jqXHR, textStatus, errorThrown) {
			// $(".waiting-indicator").addClass("active");
			console.log("jqXHR : ");
			console.log(jqXHR);
			console.log("textstatus : ");
			console.log(textStatus);
			console.log("errorThrown :");
			console.log(errorThrown);
			alert("error, check log");	};
		Game.prototype.root_url_and = function(path) {
			if(!this.id){
				return "/chess_games/"
			} else if(path){
				return "/chess_games/"+this.id+"/"+path;
			}else {
				return "/chess_games/"+this.id;
			}	};
		Game.prototype.update_request = function (path, data, type) {
			return $.ajax(this.root_url_and(path),{
					data: data,
					type: type
				});	};
		// Game.prototype.emit_and_load = function (data) {
		// 	debugger;
		// 	if(this.id){
		// 		this.socket.emit('do_update', data);
		// 	}
		// 	this.load(data);
		// 	};
		Game.prototype.attributes = function () {
			var attrs = _.pick(this, 'status', 'active_player_id', 'id');
			return attrs;	};
		Game.prototype.ping_attributes = function() {
			var ping_attrs = this.attributes();
			_.extend(ping_attrs, {
				white_player_id: this.white_player.id,
				white_accept: this.white_player.accept,
				black_player_id: this.black_player.id,
				black_accept: this.black_player.accept
			});
			return ping_attributes;
			};
		Game.prototype.loadRender = function () {
			this.id ? $("#board-state-edit").removeClass('active') : $("#board-state-edit").addClass('active');
			$("#board").empty().append(this.board_template({player_color : this.black_player && this.black_player.is_current_user() ? "black" : "white"}));
			};
		Game.prototype.load = function(data) {
			console.log("loading");
			if (typeof data === "string"){
				data = JSON.parse(data);
			}
			if(!this.id && data.id){
				this.id = data.id;
				//limsoup-chess-socketio.herokuapp.com
				this.socket = io.connect(data.socketio_url || window.location.hostname+":3020");
				this.socket.emit("join_room", this.id.toString());
				this.socket.on('do_update', _.bind(this.load, this));
				// this.socket.on('update', _.bind(this.load, this));
				console.log("socket created");
			}
			this.status = data.status;
			this.active_player_id = data.active_player_id;
			// this.moveslist = data.moveslist;
			// if(user_data){
			// 	this.current_user.load(user_data);
			// }
			this.white_player.load(data.white_player);
			this.black_player.load(data.black_player);
			this.loadRender();
			this.board_state.load(data.board);	};

		window.game = new Game(current_user_data);
		game.load(bootstrap );
	}
});