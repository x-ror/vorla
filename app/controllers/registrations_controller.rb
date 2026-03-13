class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    unless params[:terms_accepted] == "1"
      return redirect_to signup_path, alert: "You must agree to the Terms of Service, Privacy Policy, and Cookie Policy."
    end

    user = User.new(user_params)
    user.plan = "free"
    user.terms_accepted_at = Time.current

    if user.save
      # EmailVerificationMailer.verify(user).deliver_later
      # redirect_to verification_pending_path(email: user.email_address), notice: "Please check your email to verify your account."
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Welcome to X-ROR!"
    else
      redirect_to signup_path, alert: user.errors.full_messages.join(", ")
    end
  end

  private

  def user_params
    params.permit(:email_address, :password, :password_confirmation)
  end
end
