require "net/http"

class Api::ProxyController < Api::BaseController
  def show
    target_url = params[:url]&.gsub("&amp;", "&")
    return head :bad_request unless target_url.present?
    return head :forbidden unless InstagramService.allowed_proxy_domain?(target_url)

    uri = URI.parse(target_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri.request_uri)
    request["user-agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    request["accept"] = "*/*"
    request["referer"] = "https://www.instagram.com/"

    response = http.request(request)
    return head response.code.to_i unless response.is_a?(Net::HTTPSuccess)

    content_type = response["content-type"] || "application/octet-stream"

    send_data response.body,
      type: content_type,
      disposition: "inline",
      status: :ok

    headers["Cache-Control"] = "public, max-age=3600"
    headers["Access-Control-Allow-Origin"] = "*"
  rescue => e
    Rails.logger.error("Proxy error: #{e.message}")
    head :bad_gateway
  end
end
