class Api::BaseController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection
  before_action :set_current_session
  include UsageTracking

  def set_current_session
    resume_session
  end

  private

  def instagram_service
    @instagram_service ||= InstagramService.new
  end

  def proxy_url(url)
    return url unless url
    clean_url = url.gsub("&amp;", "&")
    "#{request.base_url}/api/proxy?url=#{CGI.escape(clean_url)}"
  end
end
