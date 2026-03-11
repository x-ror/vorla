class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to verification_pending_path, alert: "Try again later." }

  # GET /verify_email?token=xxx
  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user
      user.update!(verified: true)
      redirect_to login_path, notice: "Email verified successfully! Please sign in."
    else
      redirect_to login_path, alert: "Verification link is invalid or has expired."
    end
  end

  # POST /resend_verification
  def create
    if (user = User.find_by(email_address: params[:email_address]))
      EmailVerificationMailer.verify(user).deliver_later unless user.verified?
    end

    redirect_to verification_pending_path(email: params[:email_address]), notice: "If an account exists, a verification email has been sent."
  end

  # GET /verification_pending
  def pending
    @email = params[:email]
  end
end
