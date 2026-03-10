class Api::BaseController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  private

  def instagram_service
    @instagram_service ||= InstagramService.new
  end

  def proxy_url(url)
    return url unless url
    "#{request.base_url}/api/proxy?url=#{CGI.escape(url)}"
  end
end
