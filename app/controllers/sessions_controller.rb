class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: I18n.t("sessions.create.rate_limited") }

  def new
  end

  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      # unless user.verified?
      #   redirect_to verification_pending_path(email: user.email_address), alert: t("sessions.create.unverified")
      #   return
      # end

      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t("sessions.create.invalid")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
