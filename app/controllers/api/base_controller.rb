class Api::BaseController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection
  include UsageTracking

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
