class Position
	def initialize(rank, file)
		self.rank = rank
		self.file = file
	end

	def self.new_short(str)
		trank, tfile = str.split(//)
		self.new(trank.downcase.ord - 97,tfile.to_i - 1)
	end

	def clone
		Position.new(self.rank, self.file)
	end

	def short
		(rank+97).chr + (file+1).to_s
	end

	def == (otherPosition)
		self.rank == otherPosition.rank and self.file == otherPosition.file
	end

	def vertical(n)
		Position.new(self.rank, self.file+n)
	end

	def horizontal(n)
		Position.new(self.rank + n, self.file)
	end

	attr_reader :rank, :file

	private
	attr_writer :rank,:file

end