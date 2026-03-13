class BookmarksController < ApplicationController
  before_action :set_bookmark, only: :destroy

  def index
    @bookmarks = Current.user.bookmarks.includes(:items).by_type(params[:type]).recent
    @bookmark_count = Current.user.bookmarks.count
    @bookmark_limit = Current.user.current_plan == "free" ? Bookmark::FREE_LIMIT : nil
  end

  def create
    if json_request?
      create_from_json
    else
      create_from_form
    end
  end

  def destroy
    @bookmark.destroy
    if json_request?
      render json: { message: t("bookmarks.create.removed_json") }
    else
      redirect_to bookmarks_path, notice: t("bookmarks.destroy.success")
    end
  end

  private

  def create_from_json
    source_url = params[:source_url].presence || params[:url]
    media_url = params[:media_url].presence || params[:url]
    title = params[:title]

    bookmark = Bookmark.add_item(
      user: Current.user,
      source_url: source_url,
      media_url: media_url,
      title: title,
      media_type: params[:media_type],
      author: params[:author],
      caption: params[:caption],
      posted_at: params[:posted_at]
    )
    render json: { message: t("bookmarks.create.bookmarked"), id: bookmark.id, items: bookmark.items.count }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def create_from_form
    @bookmark = Current.user.bookmarks.build(params.require(:bookmark).permit(:url, :title))
    if @bookmark.save
      redirect_to bookmarks_path, notice: t("bookmarks.create.success")
    else
      @bookmarks = Current.user.bookmarks.includes(:items).by_type(params[:type]).recent
      @bookmark_count = Current.user.bookmarks.count
      @bookmark_limit = Current.user.current_plan == "free" ? Bookmark::FREE_LIMIT : nil
      render :index, status: :unprocessable_entity
    end
  end

  def set_bookmark
    @bookmark = Current.user.bookmarks.find(params[:id])
  end

  def json_request?
    request.content_type&.include?("json")
  end
end
