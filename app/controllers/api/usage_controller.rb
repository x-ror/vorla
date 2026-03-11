class Api::UsageController < Api::BaseController
  def show
    limits = UsageLog::ACTION_TYPES.each_with_object({}) do |action, hash|
      limit = UsageLog.limit_for(action, user: Current.user)
      remaining = UsageLog.remaining(action_type: action, user: Current.user, ip_address: request.remote_ip)

      hash[action] = {
        limit: limit,
        used: limit - remaining,
        remaining: remaining
      }
    end

    render json: {
      plan: Current.user&.current_plan || "guest",
      limits: limits
    }
  end
end
