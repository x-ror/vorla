class Api::StoriesController < Api::BaseController
  def create
    username = params[:username]
    return render json: { message: "Username is required" }, status: :bad_request unless username.present?

    story_url = "https://www.instagram.com/stories/#{username}/0"
    result = instagram_service.process_url(story_url)

    if result[:status] == "error"
      return render json: { message: result[:message] || "Failed to fetch stories. Instagram cookies may be required.", stories: [] }
    end

    if result[:picker]
      stories = result[:picker].map do |item|
        item.merge(
          url: proxy_url(item[:url]),
          thumbnail: proxy_url(item[:thumb]),
          timestamp: item[:timestamp]
        )
      end
      return render json: { stories: stories }
    end

    if result[:url]
      return render json: { stories: [{ type: "video", url: proxy_url(result[:url]), thumbnail: nil }] }
    end

    render json: { message: "No stories found", stories: [] }
  rescue => e
    Rails.logger.error("Stories error: #{e.message}")
    render json: { message: "Failed to fetch stories" }, status: :internal_server_error
  end
end
