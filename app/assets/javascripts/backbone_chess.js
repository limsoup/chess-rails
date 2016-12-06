/*
$(document).on('turbolinks:load', function (){

	var app = app || {};

	_.templateSettings = {
	  evaluate:    /\{\{#([\s\S]+?)\}\}/g,            // {{# console.log("blah") }}
	  interpolate: /\{\{[^#\{]([\s\S]+?)[^\}]\}\}/g,  // {{ title }}
	  escape:      /\{\{\{([\s\S]+?)\}\}\}/g,         // {{{ title }}}
	}

	if($("#app").length > 0){

		var ChessGame = Backbone.Model.extend({
			initialize: function () {
				// app_data.chess_game.movelist && new MoveListView(app_data.chess_game.movelist);
				// app_data.chess_game.board && new MoveListView(app_data.chess_game.board);
				// this.set('move_list_view', new MoveListView({data}));
				// this.set('board', new Board({game: this}));
				// this.set('white_player', new Player({game: this}));
				// this.set('black_player', new Player({game: this}));
				// grab data from global
				// app.models.white_player = new Player({app_data})
			},
			is_created: function () {
				return _.isNumber(app.game.get('id');
			},
			game_path: function() {
				var url = "/chess_games/"+this.get('id');
				return url;
			},
			ping: function(){
				var options = {
					url: this.root_path()+"/ping"
				};
				options.error = function(jqXHR, textStatus, errorThrown){
					console.log("jqXHR : ");
					console.log(jqXHR);
					console.log("textstatus : ");
					console.log(textStatus);
					console.log("errorThrown :");
					console.log(errorThrown);
					alert("error, check log");
					this.redraw();
				};

				options.success = function(data){
					this.get_game_state()
				};
				options.extend
			},
			get_game_state: function (){
				this.update_game_request({
					url: this.root_path()+"/game_state",
					type: "GET"
				});
			}
			update_game_request: function(options){
				options = _.extend({}, options);
				options.error = function(jqXHR, textStatus, errorThrown){
					console.log("jqXHR : ");
					console.log(jqXHR);
					console.log("textstatus : ");
					console.log(textStatus);
					console.log("errorThrown :");
					console.log(errorThrown);
					alert("error, check log");
					this.redraw();
				};

				options.success = function(data){
					this.reload(data);
				};
			}
			// ,
			// ping_path: function() {
			// 	return this.game_path()+"/ping";
			// },
			// game_state_path: function(){
			// 	return this.game_path()+"/game_state";
			// },
			// do_move_path: function(){
			// 	return this.game_path()+"/do_move";
			// },
			// accept_path: function(){
			// 	return this.game_path()+"/accept";
			// },
			// decline_path: function(){
			// 	return this.game_path()+"/decline";
			// }
		});

		var User = Backbone.Model.extend({
			is_invited_player : function () {
				return this.is_registered() && this.get('id') == app.white_player.get('id') || this.get('id') == app.black_player.get('id');
			},
			player: function () {
				if(this.get('id') == app.white_player.get('id')){
					return app.models.white_player;
				}else if(this.get('id') == app.black_player.get('id')){
					return app.models.black_player;
				}else{
					return null;
				}
			}
			is_registered : function (argument) {
				return _.isNumber(this.get('id'));
			}
		});


		var PlayerView = Backbone.View.extend({
			joinGameTmpl: _.template($("#join-game-template").html()),
			inviteTmpl: _.template($("#invite-template").html()),
			acceptDeclineTmpl: _.template($("#accept-decline-template").html()),
			playerTmpl: _.template($("#player-template").html()),
			capturesTmpl: _.template($("#captures-template").html()),
			tagName: "div",
			className: "player",
			events : {
				"click .join-game-btn" : "join_game",
				"click .invite-btn" : "invite_selected",
				"click .decline-btn" : "decline",
				"click .accept-btn" : "accept"
			},
			decline: function (e) {
				this.model.decline();
			},
			accept : function (e) {
				this.model.accept();
			},
			invite_selected: function (e) {
				var selectedID = this.$el.find('.invite-select option:selected').val()
				if(selectedID !== null && selectedID !== undefined ){
					this.model.invite(this.$el.find('.invite-select option:selected').val());
				}
			},
			join_game: function (e) {
				this.model.join_game();
			},
			initialize: function (options) {
				this.options = options || {};
				this.listenTo(this.model, "update", this.render);
				var player_div = $(".players ."+this.model.get('color'));
				this.$el.addClass(this.model.get('color'));
				player_div.append(this.el);
				this.render();
			},
			render : function () {
				// var m = this.model;
				// m.can_edit() && this.append(this.signupTmpl(app.models.game.all_users));
				this.$el.empty();
				this.$el.append(this.playerTmpl(this.model.renderJSON()));
				m.can_join_game() && this.$el.append(this.joinGameTmpl());
				m.can_take_invite() && this.$el.append(this.inviteTmpl( app.models.game.all_users() ));
				m.can_accept_or_decline() && this.$el.append(this.acceptDeclineTmpl(this.model))
			}
		});


		var Player = Backbone.Model.extend({
			initialize: function(){
				this.on('change',)
			}
			is_current_user: function () {
				return app.current_user.is_registered() && app.current_user.get('id') == this.get('id')
			},
			opponent: function () {
				if(this.get('color') == "white"){
					return app.black_player;
				}else{
					return app.white_player;
				}
			},
			can_accept_or_decline: function () {
				if(app.current_user.is_invited_player() && this.get("accepted") === null ){
					return true;
				}
				return false;
			},
			can_join_game: function () {
				return app.current_user && !app.current_user.is_invited_player() && app.game.is_created();
			}
			can_edit: function () {
				return app.current_user && !(app.game.is_created());
			},
			can_take_invite: function () {
				if((app.game.get('status') == 'Not Started') && (app.current_user.is_invited_player())){
					if(this.get('accepted') === true){
						if(this.opponent().is_registered()) {
							return true;
						}
					}
				}
				return false;
			},
			renderJSON: function (){
				var robj = {};
				robj.color = this.get('color');
				robj.name = this.is_current_user() ? "Me" : this.get('email');
				robj.captures = this.get('captures');
				robj.has_turn = app.models.game.get('active_player_id') == this.get('id') ? true : false;
				return robj;
			},
			accept: function () {
				this.update_game_request({
					url: app.models.game.root_url()+"/accept",
					type: 'POST'
				});
			},
			decline: function () {
				this.update_game_request({
					url: app.models.game.root_url()+"/decline",
					type: 'POST'
				});
			},
			join_game: function () {
				this.set({id: app.models.current_user.id, accepted: true});
				this.update_game_request({
					url: app.models.game.root_url()+"/decline",
					type: 'POST'
				});
			},
			invite: function () {
				this.set({id: app.models.current_user.id, accepted: null});
				this.update_game_request({
					url: app.models.game.root_url()+"/decline",
					type: 'POST'
				});
			}

		});



		function bootstrap() {
			app.models = app.model || {};
			app.views = app.views || {};
			app.models.game = new Game(app_data.game_data);
			app.models.current_user = new User(app_data.current_user);
			app.models.white_player = new Player(app_data.white_player);
			app.models.black_player = new Player(app_data.black_player);
			app.views.white_player = new PlayerView(app.models.white_player);
			app.views.black_player = new PlayerView(app.models.black_player);
		}

		bootstrap(app_data);
	}
});

*/