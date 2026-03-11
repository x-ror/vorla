class Session < ApplicationRecord
  belongs_to :user

  def device_name
    case user_agent
    when /iPhone/i then "iPhone"
    when /iPad/i then "iPad"
    when /Android/i then "Android"
    when /Mac OS/i then "Mac"
    when /Windows/i then "Windows"
    when /Linux/i then "Linux"
    else "Unknown device"
    end
  end

  def browser_name
    case user_agent
    when /Edg/i then "Edge"
    when /OPR|Opera/i then "Opera"
    when /Chrome/i then "Chrome"
    when /Safari/i then "Safari"
    when /Firefox/i then "Firefox"
    else "Unknown browser"
    end
  end
end
