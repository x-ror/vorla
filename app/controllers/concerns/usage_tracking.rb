module UsageTracking
  extend ActiveSupport::Concern

  private

  def track_usage!(action_type)
    if UsageLog.limit_reached?(action_type: action_type, user: Current.user, ip_address: request.remote_ip)
      limit = UsageLog.limit_for(action_type, user: Current.user)
      render json: {
        message: "Daily limit reached (#{limit}/24h). Please try again later.",
        limit_reached: true,
        limit: limit,
        resets_in: resets_in_text(action_type)
      }, status: :too_many_requests
      return false
    end

    UsageLog.create!(
      user: Current.user,
      action_type: action_type,
      ip_address: request.remote_ip,
      session_token: cookies.signed[:session_id],
      metadata: { user_agent: request.user_agent }
    )
    true
  end

  def resets_in_text(action_type)
    scope = UsageLog.recent.for_action(action_type)
    scope = Current.user ? scope.where(user: Current.user) : scope.where(ip_address: request.remote_ip, user: nil)
    oldest = scope.order(:created_at).first
    return nil unless oldest

    seconds = (oldest.created_at + 24.hours - Time.current).to_i
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    "#{hours}h #{minutes}m"
  end
end
