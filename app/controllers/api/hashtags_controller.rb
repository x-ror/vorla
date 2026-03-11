class Api::HashtagsController < Api::BaseController
  def create
    topic = params[:topic]
    return render json: { message: "Topic is required" }, status: :bad_request unless topic.present?
    return unless track_usage!("hashtags", query: topic)

    hashtags = HashtagService.generate(topic)
    render json: { topic: topic, hashtags: hashtags }
  rescue => e
    Rails.logger.error("Hashtags error: #{e.message}")
    render json: { message: "Failed to generate hashtags" }, status: :internal_server_error
  end
end
