class HistoryController < ApplicationController
  def index
    scope = Current.user.usage_logs.order(created_at: :desc)
    scope = scope.for_action(params[:type]) if params[:type].present?
    @logs = scope.limit(100)
  end
end
