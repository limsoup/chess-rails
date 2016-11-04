class  UsersController < ApplicationController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  def new
  	@user = User.new
  end

  def create
  	user = User.create!(create_params)
    session[:user_id] = user.id
  	redirect_to user
  end

  def show
  	@user = User.find(params[:id])
  end

  def index
    @users = User.all
  end

  private 

  def create_params
  	params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

end
