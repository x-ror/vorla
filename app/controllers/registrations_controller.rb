class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    user = User.new(user_params)
    user.plan = "free"

    if user.save
      start_new_session_for(user)
      redirect_to download_path, notice: "Welcome to Vorla!"
    else
      redirect_to signup_path, alert: user.errors.full_messages.join(", ")
    end
  end

  private

  def user_params
    params.permit(:email_address, :password, :password_confirmation)
  end
end
