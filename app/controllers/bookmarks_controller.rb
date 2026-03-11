class BookmarksController < ApplicationController
  before_action :set_bookmark, only: :destroy

  def index
    @bookmarks = Current.user.bookmarks.by_type(params[:type]).recent
    @bookmark = Bookmark.new
    @bookmark_count = Current.user.bookmarks.count
    @bookmark_limit = Current.user.current_plan == "free" ? Bookmark::FREE_LIMIT : nil
  end

  def create
    @bookmark = Current.user.bookmarks.build(bookmark_params)

    if @bookmark.save
      redirect_to bookmarks_path, notice: "Bookmark saved!"
    else
      @bookmarks = Current.user.bookmarks.by_type(params[:type]).recent
      @bookmark_count = Current.user.bookmarks.count
      @bookmark_limit = Current.user.current_plan == "free" ? Bookmark::FREE_LIMIT : nil
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @bookmark.destroy
    redirect_to bookmarks_path, notice: "Bookmark removed."
  end

  private

  def set_bookmark
    @bookmark = Current.user.bookmarks.find(params[:id])
  end

  def bookmark_params
    params.require(:bookmark).permit(:url, :title)
  end
end
