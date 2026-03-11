class ProfilesController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_avatar
    unless params[:avatar]&.content_type&.start_with?("image/")
      redirect_to profile_path, alert: "Please select a valid image."
      return
    end

    @user.avatar.attach(params[:avatar])
    redirect_to profile_path
  end

  def remove_avatar
    @user.avatar.purge
    redirect_to profile_path
  end

  def connect_instagram
    username = params[:instagram_username].to_s.strip.delete_prefix("@")

    if username.blank?
      redirect_to profile_path, alert: "Please enter an Instagram username."
      return
    end

    @user.update!(
      instagram_username: username,
      instagram_connected_at: Time.current
    )
    redirect_to profile_path
  end

  def disconnect_instagram
    @user.update!(
      instagram_username: nil,
      instagram_id: nil,
      instagram_connected_at: nil
    )
    redirect_to profile_path
  end

  private

  def set_user
    @user = Current.user
  end

  def profile_params
    params.require(:user).permit(:full_name, :bio)
  end
end
