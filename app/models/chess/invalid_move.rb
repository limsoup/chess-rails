class InvalidMoveError < StandardError
  def initialize(msg="Invalid Move")
    super
  end
end