class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to verification_pending_path, alert: I18n.t("email_verifications.create.rate_limited") }

  # GET /verify_email?token=xxx
  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user
      user.update!(verified: true)
      redirect_to login_path, notice: t("email_verifications.show.success")
    else
      redirect_to login_path, alert: t("email_verifications.show.invalid")
    end
  end

  # POST /resend_verification
  def create
    if (user = User.find_by(email_address: params[:email_address]))
      EmailVerificationMailer.verify(user).deliver_later unless user.verified?
    end

    redirect_to verification_pending_path(email: params[:email_address]), notice: t("email_verifications.create.sent")
  end

  # GET /verification_pending
  def pending
    @email = params[:email]
  end
end
