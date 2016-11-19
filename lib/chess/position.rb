# encoding: utf-8
class Position
	def initialize(rank, file)
		self.rank = rank
		self.file = file
	end

	def self.new_short(str)
		trank, tfile = str.split(//)
		# debugger
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

	def is_between? segment
		a = Position.new_short(segment[0])
		b = Position.new_short(segment[1])
		if a.rank == b.rank
			rank == a.rank and file.between?(a.file, b.file)
		elsif a.file == b.file
			file == a.file and rank.between?(a.rank, b.rank)
		elsif (a.rank - a.file) == (b.rank - b.file)
			(rank - file) == (a.rank - a.file) and rank.between?(a.rank, b.rank) and file.between?(a.file, b.file)
		else
			false
		end
	end

	def in_bounds?
		rank > -1 and rank < 8 and file > -1 and file < 8
	end

	attr_reader :rank, :file

	private
	attr_writer :rank,:file

end