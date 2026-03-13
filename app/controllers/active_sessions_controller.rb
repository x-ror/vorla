class ActiveSessionsController < ApplicationController
  # GET /active_sessions
  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
    @current_session = Current.session
    @passkey_credentials = Current.user.passkey_credentials.order(created_at: :desc)
  end

  # DELETE /active_sessions/:id
  def destroy
    session_record = Current.user.sessions.find(params[:id])

    if session_record == Current.session
      redirect_to active_sessions_path, alert: t("active_sessions.destroy.cannot_revoke_current")
    else
      session_record.destroy
      redirect_to active_sessions_path, notice: t("active_sessions.destroy.success")
    end
  end

  # DELETE /active_sessions/destroy_all
  def destroy_all
    Current.user.sessions.where.not(id: Current.session.id).destroy_all
    redirect_to active_sessions_path, notice: t("active_sessions.destroy_all.success")
  end
end
