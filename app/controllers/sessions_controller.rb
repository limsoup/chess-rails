class SessionsController < ApplicationController
	def new
		redirect_to current_user if current_user
	end

	def create
		user = User.find_by_email params[:email]
		if user and user.authenticate(params[:password])
			session[:user_id] = user.id
			redirect_to user
		else
			render 'new'
		end
	end

	def destroy
		session[:user_id] = nil
		redirect_to root_path
	end
end