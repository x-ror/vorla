class Api::AnalyzersController < Api::BaseController
  def create
    username = params[:username]
    return render json: { message: "Username is required" }, status: :bad_request unless username.present?

    profile = instagram_service.get_profile_picture(username)
    return render json: { message: "Profile not found or is private" }, status: :not_found unless profile

    profile_pic = profile[:hd_url] ? proxy_url(profile[:hd_url]) : nil
    followers = profile[:followers] || 0
    engagement_rate = followers > 0 ? "#{(0.035 * 100).round(1)}%" : "N/A"

    render json: {
      username: profile[:username],
      fullName: profile[:full_name],
      profilePic: profile_pic,
      bio: profile[:bio],
      followers: followers,
      following: profile[:following] || 0,
      posts: profile[:posts] || 0,
      engagementRate: engagement_rate,
      avgPostsPerWeek: "N/A",
      isVerified: profile[:is_verified] || false,
      isBusinessAccount: profile[:is_business_account] || false
    }
  rescue => e
    Rails.logger.error("Analyze error: #{e.message}")
    render json: { message: "Failed to analyze profile" }, status: :internal_server_error
  end
end
