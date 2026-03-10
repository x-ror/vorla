class Api::DownloadsController < Api::BaseController
  def create
    url = params[:url]
    return render json: { message: "URL is required" }, status: :bad_request unless url.present?

    result = instagram_service.process_url(url, quality: params[:videoQuality] || "1080")

    if result[:status] == "error"
      return render json: { message: result[:message], error: result[:error] }, status: :bad_request
    end

    # Rewrite CDN URLs through proxy
    result[:url] = proxy_url(result[:url]) if result[:url]

    if result[:picker]
      result[:picker] = result[:picker].map do |item|
        item.merge(
          url: proxy_url(item[:url]),
          thumb: proxy_url(item[:thumb])
        )
      end
    end

    render json: result
  rescue => e
    Rails.logger.error("Download error: #{e.message}")
    render json: { message: "Internal server error" }, status: :internal_server_error
  end
end
