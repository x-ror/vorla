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

  def history_action_icon(action_type)
    case action_type
    when "download" then "download"
    when "stories" then "book-open"
    when "profile_picture" then "user"
    when "analyze" then "chart-bar"
    when "hashtags" then "hash"
    else "clock"
    end
  end

  def history_action_label(action_type)
    case action_type
    when "download" then "Download"
    when "stories" then "Stories"
    when "profile_picture" then "Profile Pic"
    when "analyze" then "Analyzer"
    when "hashtags" then "Hashtags"
    else action_type.humanize
    end
  end

  def history_action_path(action_type, query)
    case action_type
    when "download" then download_path(url: query)
    when "stories" then stories_path
    when "profile_picture" then profile_picture_path
    when "analyze" then analyzer_path
    when "hashtags" then hashtags_path
    end
  end
end
