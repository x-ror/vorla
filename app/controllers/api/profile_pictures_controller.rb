class Api::ProfilePicturesController < Api::BaseController
  def create
    username = params[:username]
    return render json: { message: "Username is required" }, status: :bad_request unless username.present?
    return unless track_usage!("profile_picture", query: username)

    result = instagram_service.get_profile_picture(username)
    return render json: { message: "Profile not found or is private" }, status: :not_found unless result

    result[:hd_url] = proxy_url(result[:hd_url]) if result[:hd_url]

    render json: {
      username: result[:username],
      fullName: result[:full_name],
      hdUrl: result[:hd_url],
      followers: result[:followers],
      following: result[:following],
      posts: result[:posts],
      bio: result[:bio],
      isVerified: result[:is_verified],
      isBusinessAccount: result[:is_business_account]
    }
  rescue => e
    Rails.logger.error("Profile picture error: #{e.message}")
    render json: { message: "Failed to fetch profile picture" }, status: :internal_server_error
  end
end
