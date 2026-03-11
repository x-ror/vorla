class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    user = User.new(user_params)
    user.plan = "free"

    if user.save
      # EmailVerificationMailer.verify(user).deliver_later
      # redirect_to verification_pending_path(email: user.email_address), notice: "Please check your email to verify your account."
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Welcome to Vorla!"
    else
      redirect_to signup_path, alert: user.errors.full_messages.join(", ")
    end
  end

  private

  def user_params
    params.permit(:email_address, :password, :password_confirmation)
  end
end
