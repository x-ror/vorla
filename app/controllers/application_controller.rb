class ApplicationController < ActionController::Base
  include Authentication
  include SetLocale
  allow_browser versions: :modern
  stale_when_importmap_changes

  private

  def current_plan
    Current.user&.current_plan || "free"
  end
  helper_method :current_plan

  def can_access?(feature)
    Current.user&.can_access?(feature) || User::PLANS["free"][:features].include?(feature.to_s)
  end
  helper_method :can_access?

  def require_feature!(feature)
    unless can_access?(feature)
      redirect_to pricing_path, alert: t("flash.upgrade_required")
    end
  end
end
