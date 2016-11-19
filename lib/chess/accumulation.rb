# encoding: utf-8
#so this probably doesn't need to be a module of its
#own to give different classes different behaviors.

module ContinueOnPath
	def aggregator(direction)
		run_1_watches = []
		run_2_watches = []

		run_1 = true
		run_2 = false
		blocker_1 = nil
		capture_1 = nil
		blocker_2 = nil

		while run_1
			current_position = (current_position || position).horizontal(direction[0,0]).vertical(direction[0,1])
			if current_position.in_bounds?
				blocker_1 = board.get_piece current_position
				capture_1 = blocker_1 if blocker_1 and blocker_1.color != color
				run_1_watches << {
					can_move: (!!capture_1 or !blocker_1),
					can_attack: (!!capture_1 or !blocker_1),
					watcher_position: self.position.short,
					watched_position: current_position.short
				}
				run_1 = !blocker_1
			else
				run_1 = false
			end
		end

		if capture_1
			run_2 = true
			while run_2
				current_position = current_position.horizontal(direction[0,0]).vertical(direction[0,1])
				if current_position.in_bounds?
					blocker_2 = board.get_piece current_position
					capture_2 = blocker_2 if blocker_2 and blocker_2.color != color
					run_2_watches << {
						can_move: false,
						can_attack: false,
						watcher_position: self.position.short,
						watched_position: current_position.short
					}
					run_2 = !blocker_2
				else
					run_2 = false
				end
			end
		end

		watches = run_1_watches.concat run_2_watches
		watches.each do |watch|
			watch[:attack_line] = [self.position.short, watches.last[:watched_position]]
		end

		watches.each { |watch| board.register_watch(watch)  }
	end
end

module OnceOnPath
	def aggregator(direction)
		current_position = position.horizontal(direction[0,0]).vertical(direction[0,1])
		register_watch_if_in_bounds(current_position)
		# if board.in_bounds? current_position
		# 	blocker = get_piece current_position
		# 	capture = blocker if blocker.color != color
		# 	board.register_watch({
		# 		can_move: !!capture or !blocker,
		# 		can_attack: !!capture or !blocker,
		# 		watcher_position: self.position,
		# 		watched_position: current_position
		# 	})
		# end
	end
end

