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
      redirect_to active_sessions_path, alert: "You cannot revoke your current session."
    else
      session_record.destroy
      redirect_to active_sessions_path, notice: "Session revoked."
    end
  end

  # DELETE /active_sessions/destroy_all
  def destroy_all
    Current.user.sessions.where.not(id: Current.session.id).destroy_all
    redirect_to active_sessions_path, notice: "All other sessions revoked."
  end
end
