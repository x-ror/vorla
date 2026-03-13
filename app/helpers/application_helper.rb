module ApplicationHelper
  def bookmark_type_icon(type)
    case type
    when "post" then "image"
    when "reel" then "film"
    when "story" then "circle-play"
    when "account" then "user"
    else "bookmark"
    end
  end
end
