class BookmarksController < ApplicationController
  before_action :set_bookmark, only: :destroy

  def index
    @bookmarks = Current.user.bookmarks.by_type(params[:type]).recent
    @bookmark_count = Current.user.bookmarks.count
    @bookmark_limit = Current.user.current_plan == "free" ? Bookmark::FREE_LIMIT : nil
  end

  def create
    @bookmark = Current.user.bookmarks.build(bookmark_params)

    if @bookmark.save
      if json_request?
        render json: { message: "Bookmarked!", id: @bookmark.id }, status: :created
      else
        redirect_to bookmarks_path, notice: "Bookmark saved!"
      end
    else
      if json_request?
        existing = Current.user.bookmarks.find_by(url: @bookmark.url)
        if existing
          render json: { message: "Already bookmarked!", id: existing.id }, status: :ok
        else
          render json: { message: @bookmark.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end
      else
        @bookmarks = Current.user.bookmarks.by_type(params[:type]).recent
        @bookmark_count = Current.user.bookmarks.count
        @bookmark_limit = Current.user.current_plan == "free" ? Bookmark::FREE_LIMIT : nil
        render :index, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @bookmark.destroy
    if json_request?
      render json: { message: "Removed." }
    else
      redirect_to bookmarks_path, notice: "Bookmark removed."
    end
  end

  private

  def set_bookmark
    @bookmark = Current.user.bookmarks.find(params[:id])
  end

  def json_request?
    request.content_type&.include?("json")
  end

  def bookmark_params
    if json_request?
      params.permit(:url, :title)
    else
      params.require(:bookmark).permit(:url, :title)
    end
  end
end
