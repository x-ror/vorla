class AccountsController < ApplicationController
  before_action :set_user

  def show
  end

  def destroy
    unless Current.user.authenticate(params[:password])
      redirect_to account_path, alert: "Incorrect password. Account not deleted."
      return
    end

    # Purge avatar from cloud storage
    @user.avatar.purge if @user.avatar.attached?

    # Destroy user and all associated data (cascading via model associations)
    @user.destroy

    # Clear session cookie
    cookies.delete(:session_id)
    reset_session

    redirect_to root_path, notice: "Your account and all associated data have been permanently deleted."
  end

  def export
    data = {
      exported_at: Time.current.iso8601,
      account: {
        email: @user.email_address,
        full_name: @user.full_name,
        bio: @user.bio,
        plan: @user.current_plan,
        instagram_username: @user.instagram_username,
        created_at: @user.created_at&.iso8601,
        updated_at: @user.updated_at&.iso8601
      },
      sessions: @user.sessions.map { |s|
        {
          ip_address: s.ip_address,
          user_agent: s.user_agent,
          created_at: s.created_at&.iso8601
        }
      },
      bookmarks: @user.bookmarks.includes(:items).map { |b|
        {
          url: b.url,
          bookmark_type: b.bookmark_type,
          title: b.title,
          author: b.author,
          caption: b.caption,
          instagram_username: b.instagram_username,
          posted_at: b.posted_at&.iso8601,
          created_at: b.created_at&.iso8601,
          items: b.items.map { |i|
            {
              media_url: i.media_url,
              media_type: i.media_type,
              title: i.title
            }
          }
        }
      },
      usage_history: @user.usage_logs.order(created_at: :desc).limit(1000).map { |l|
        {
          action_type: l.action_type,
          created_at: l.created_at&.iso8601
        }
      }
    }

    send_data data.to_json,
      filename: "x-ror-data-export-#{Date.current}.json",
      type: "application/json",
      disposition: "attachment"
  end

  private

  def set_user
    @user = Current.user
  end
end
