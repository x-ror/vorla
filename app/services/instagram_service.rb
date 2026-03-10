require "net/http"
require "json"
require "uri"
require "securerandom"

class InstagramService
  INSTAGRAM_APP_ID = "936619743392459"
  MOBILE_APP_ID = "567067343352427"
  GQL_DOC_ID = "8845758582119845"
  STORIES_DOC_ID = "25317500907894419"

  COMMON_HEADERS = {
    "accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "accept-language" => "en-US,en;q=0.9",
    "sec-fetch-dest" => "document",
    "sec-fetch-mode" => "navigate",
    "sec-fetch-site" => "none",
    "x-ig-app-id" => INSTAGRAM_APP_ID,
    "user-agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
  }.freeze

  MOBILE_HEADERS = {
    "user-agent" => "Instagram 275.0.0.27.98 Android (33/13; 280dpi; 720x1423; Xiaomi; Mi A2 Lite; daisy_sprout; qcom; en_US; 458229237)",
    "accept" => "*/*",
    "accept-language" => "en-US,en;q=0.9",
    "x-ig-app-id" => MOBILE_APP_ID,
    "x-fb-http-engine" => "Liger"
  }.freeze

  EMBED_HEADERS = {
    "accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "accept-language" => "en-US,en;q=0.5",
    "sec-fetch-dest" => "iframe",
    "sec-fetch-mode" => "navigate",
    "sec-fetch-site" => "cross-site",
    "sec-gpc" => "1",
    "user-agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
  }.freeze

  URL_PATTERNS = [
    { pattern: /^\/p\/([A-Za-z0-9_-]+)/, extract: ->(m) { { post_id: m[1] } } },
    { pattern: /^\/tv\/([A-Za-z0-9_-]+)/, extract: ->(m) { { post_id: m[1] } } },
    { pattern: /^\/reels?\/([A-Za-z0-9_-]+)/, extract: ->(m) { { post_id: m[1] } } },
    { pattern: /^\/stories\/([A-Za-z0-9_.]+)\/(\d+)/, extract: ->(m) { { username: m[1], story_id: m[2] } } },
    { pattern: /^\/share\/p\/([A-Za-z0-9_-]+)/, extract: ->(m) { { share_id: m[1], share_type: "p" } } },
    { pattern: /^\/share\/reel\/([A-Za-z0-9_-]+)/, extract: ->(m) { { share_id: m[1], share_type: "reel" } } },
    { pattern: /^\/share\/([A-Za-z0-9_-]+)/, extract: ->(m) { { share_id: m[1] } } },
    { pattern: /^\/([A-Za-z0-9_.]+)\/p\/([A-Za-z0-9_-]+)/, extract: ->(m) { { post_id: m[2] } } },
    { pattern: /^\/([A-Za-z0-9_.]+)\/reel\/([A-Za-z0-9_-]+)/, extract: ->(m) { { post_id: m[2] } } }
  ].freeze

  ALLOWED_PROXY_DOMAINS = %w[
    scontent.cdninstagram.com
    instagram.com
    cdninstagram.com
    fbcdn.net
  ].freeze

  def initialize
    @cookie = ENV["INSTAGRAM_COOKIE"].to_s
    @bearer = ENV["INSTAGRAM_BEARER"].to_s
    @ig_www_claim = "0"
    @dtsg_cache = { token: nil, expiry: 0 }
  end

  # ---------- Main entry point ----------

  def process_url(url, quality: "1080")
    parsed = parse_url(url)
    return error_result("link.unsupported", "Invalid or unsupported Instagram URL") unless parsed

    if parsed[:share_id]
      resolved = resolve_share_link(parsed[:share_id])
      return error_result("fetch.fail", "Could not resolve share link") unless resolved
      return get_post(resolved[:post_id], quality) if resolved[:post_id]
      return get_story(resolved[:username], resolved[:story_id]) if resolved[:username] && resolved[:story_id]
      return error_result("link.unsupported", "Unsupported share link type")
    end

    return get_story(parsed[:username], parsed[:story_id]) if parsed[:username] && parsed[:story_id]
    return get_post(parsed[:post_id], quality) if parsed[:post_id]

    error_result("link.unsupported", "Could not determine content type from URL")
  end

  def get_profile_picture(username)
    headers = COMMON_HEADERS.dup
    headers["cookie"] = @cookie if @cookie.present?

    data = fetch_json(
      "https://www.instagram.com/api/v1/users/web_profile_info/?username=#{username}",
      headers: headers
    )

    user = data&.dig("data", "user")
    if user
      return {
        username: user["username"],
        full_name: user["full_name"],
        hd_url: user.dig("hd_profile_pic_url_info", "url") || user["profile_pic_url_hd"] || user["profile_pic_url"],
        followers: user.dig("edge_followed_by", "count") || user["follower_count"],
        following: user.dig("edge_follow", "count") || user["following_count"],
        posts: user.dig("edge_owner_to_timeline_media", "count") || user["media_count"],
        bio: user["biography"],
        is_verified: user["is_verified"],
        is_business_account: user["is_business_account"] || user["is_professional_account"]
      }
    end

    # Fallback: scrape meta tags
    html = fetch_text("https://www.instagram.com/#{username}/", headers: COMMON_HEADERS.dup)
    return nil unless html

    og_image = html[/<meta property="og:image" content="([^"]+)"/, 1]&.gsub("&amp;", "&")
    og_title = html[/<meta property="og:title" content="([^"]+)"/, 1]
    return nil unless og_image

    {
      username: username,
      full_name: og_title&.match(/^(.+?)(?:\s*\()/)&.[](1)&.strip,
      hd_url: og_image
    }
  end

  def self.allowed_proxy_domain?(url)
    parsed = URI.parse(url)
    ALLOWED_PROXY_DOMAINS.any? { |domain| parsed.host == domain || parsed.host&.end_with?(".#{domain}") }
  rescue URI::InvalidURIError
    false
  end

  private

  def error_result(error, message)
    { status: "error", error: error, message: message }
  end

  # ---------- URL parsing ----------

  def parse_url(url)
    parsed = URI.parse(url)
    host = parsed.host&.sub("www.", "")
    return nil unless %w[instagram.com ddinstagram.com].include?(host)

    path = parsed.path
    URL_PATTERNS.each do |entry|
      match = path.match(entry[:pattern])
      return entry[:extract].call(match) if match
    end

    nil
  rescue URI::InvalidURIError
    nil
  end

  # ---------- Fetch helpers ----------

  def fetch_json(url, headers: {}, method: :get, body: nil)
    response = http_request(url, headers: headers, method: method, body: body)
    return nil unless response&.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  rescue JSON::ParserError
    nil
  end

  def fetch_text(url, headers: {}, method: :get, body: nil)
    response = http_request(url, headers: headers, method: method, body: body)
    return nil unless response&.is_a?(Net::HTTPSuccess)
    response.body
  end

  def http_request(url, headers: {}, method: :get, body: nil, follow_redirects: true)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 15

    request = case method
    when :post
      req = Net::HTTP::Post.new(uri.request_uri)
      req.body = body if body
      req
    else
      Net::HTTP::Get.new(uri.request_uri)
    end

    headers.each { |k, v| request[k] = v }
    response = http.request(request)

    if follow_redirects && response.is_a?(Net::HTTPRedirection) && response["location"]
      return http_request(response["location"], headers: headers, method: method, body: body)
    end

    response
  rescue StandardError => e
    Rails.logger.error("Instagram HTTP error: #{e.message}")
    nil
  end

  # ---------- Media ID resolution ----------

  def get_media_id(post_id)
    data = fetch_json(
      "https://i.instagram.com/api/v1/oembed/?url=https://www.instagram.com/p/#{post_id}/",
      headers: COMMON_HEADERS.dup
    )
    data&.[]("media_id")
  end

  # ---------- Mobile API ----------

  def fetch_mobile_api(media_id, use_cookie: false)
    headers = MOBILE_HEADERS.dup
    headers["authorization"] = "Bearer #{@bearer}" if @bearer.present?
    if use_cookie && @cookie.present?
      headers["cookie"] = @cookie
      headers["x-ig-www-claim"] = @ig_www_claim
    end

    data = fetch_json(
      "https://i.instagram.com/api/v1/media/#{media_id}/info/",
      headers: headers
    )
    data&.dig("items", 0)
  end

  # ---------- Embed scraping ----------

  def fetch_embed(post_id, use_cookie: false)
    headers = EMBED_HEADERS.dup
    headers["cookie"] = @cookie if use_cookie && @cookie.present?

    html = fetch_text(
      "https://www.instagram.com/p/#{post_id}/embed/captioned/",
      headers: headers
    )
    return nil unless html

    video_match = html.match(/"video_url":"([^"]+)"/)
    image_match = html.match(/"display_url":"([^"]+)"/) || html.match(/class="EmbeddedMediaImage"[^>]*src="([^"]+)"/)
    sidecar_match = html.include?('"edge_sidecar_to_children"')

    if sidecar_match
      script_match = html.match(/window\.__additionalDataLoaded\s*\(\s*'[^']*'\s*,\s*({.+?})\s*\)/m) ||
                     html.match(/"shortcode_media"\s*:\s*({.+?})\s*[,}]/m)
      if script_match
        begin
          data = JSON.parse(script_match[1])
          media = data["shortcode_media"] || data
          return { type: "embed_json", data: media } if media["edge_sidecar_to_children"]
        rescue JSON::ParserError
          # continue
        end
      end
    end

    if video_match
      video_url = video_match[1].gsub(/\\u0026/, "&").delete("\\")
      return { type: "video", url: video_url }
    end

    if image_match
      image_url = image_match[1].gsub(/\\u0026/, "&").delete("\\")
      return { type: "photo", url: image_url }
    end

    nil
  end

  # ---------- GraphQL API ----------

  def fetch_dtsg
    if @dtsg_cache[:token] && Time.now.to_i < @dtsg_cache[:expiry]
      return @dtsg_cache[:token]
    end

    headers = COMMON_HEADERS.dup
    headers["cookie"] = @cookie if @cookie.present?

    html = fetch_text("https://www.instagram.com/", headers: headers)
    return nil unless html

    match = html.match(/"DTSGInitialData".*?"token":"([^"]+)"/)
    if match
      @dtsg_cache = { token: match[1], expiry: Time.now.to_i + 86400 }
      return match[1]
    end

    nil
  end

  def fetch_graphql(post_id, use_cookie: false)
    headers = COMMON_HEADERS.merge(
      "content-type" => "application/x-www-form-urlencoded",
      "x-fb-friendly-name" => "PolarisPostActionLoadPostQueryQuery",
      "x-requested-with" => "XMLHttpRequest",
      "referer" => "https://www.instagram.com/p/#{post_id}/"
    )

    if use_cookie && @cookie.present?
      headers["cookie"] = @cookie
      headers["x-ig-www-claim"] = @ig_www_claim
      dtsg = fetch_dtsg
      headers["x-fb-dtsg"] = dtsg if dtsg
    else
      embed_html = fetch_text("https://www.instagram.com/p/#{post_id}/", headers: COMMON_HEADERS.dup)
      if embed_html
        csrf_match = embed_html.match(/"csrf_token":"([^"]+)"/)
        if csrf_match
          device_id = SecureRandom.uuid
          headers["cookie"] = "csrftoken=#{csrf_match[1]}; ig_did=#{device_id}; mid=#{generate_mid}"
          headers["x-csrftoken"] = csrf_match[1]
        end
      end
    end

    variables = { shortcode: post_id, fetch_tagged_user_count: nil, hoisted_comment_id: nil, hoisted_reply_id: nil }
    body = URI.encode_www_form(variables: variables.to_json, doc_id: GQL_DOC_ID)

    data = fetch_json(
      "https://www.instagram.com/graphql/query",
      headers: headers, method: :post, body: body
    )

    data&.dig("data", "xdt_shortcode_media") || data&.dig("data", "shortcode_media")
  end

  def generate_mid
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    (0...28).map { chars[rand(chars.length)] }.join
  end

  # ---------- Share link resolution ----------

  def resolve_share_link(share_id)
    uri = URI.parse("https://www.instagram.com/share/#{share_id}/")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request["user-agent"] = "curl/8.0"
    request["accept"] = "*/*"
    response = http.request(request)

    location = response["location"]
    return nil unless location

    parse_url(location)
  rescue StandardError
    nil
  end

  # ---------- Data extraction ----------

  def pick_best_video(versions)
    return nil if versions.nil? || versions.empty?
    versions.max_by { |v| (v["width"] || 0) * (v["height"] || 0) }
  end

  def extract_new_post(data, post_id)
    return nil unless data

    # Carousel
    if data["carousel_media"]
      picker = data["carousel_media"].filter_map do |item|
        if item["video_versions"]
          best = pick_best_video(item["video_versions"])
          { type: "video", url: best&.[]("url"), thumb: item.dig("image_versions2", "candidates", 0, "url") }
        else
          url = item.dig("image_versions2", "candidates", 0, "url")
          { type: "photo", url: url, thumb: url }
        end
      end.select { |i| i[:url] }

      return nil if picker.empty?
      return { status: "picker", picker: picker }
    end

    # Single video
    if data["video_versions"]
      best = pick_best_video(data["video_versions"])
      return { status: "redirect", url: best&.[]("url"), filename: "instagram_#{post_id}.mp4" }
    end

    # Single photo
    candidates = data.dig("image_versions2", "candidates")
    if candidates&.any?
      return { status: "redirect", url: candidates[0]["url"], filename: "instagram_#{post_id}.jpg" }
    end

    nil
  end

  def extract_old_post(data, post_id)
    return nil unless data

    media = data["shortcode_media"] || data

    # Sidecar / carousel
    edges = media.dig("edge_sidecar_to_children", "edges")
    if edges
      picker = edges.filter_map do |edge|
        node = edge["node"]
        if node["is_video"] || node["video_url"]
          { type: "video", url: node["video_url"], thumb: node["display_url"] }
        else
          { type: "photo", url: node["display_url"], thumb: node["display_url"] }
        end
      end.select { |i| i[:url] }

      return nil if picker.empty?
      return { status: "picker", picker: picker }
    end

    # Single video
    if media["is_video"] && media["video_url"]
      return { status: "redirect", url: media["video_url"], filename: "instagram_#{post_id}.mp4" }
    end

    # Single photo
    if media["display_url"]
      return { status: "redirect", url: media["display_url"], filename: "instagram_#{post_id}.jpg" }
    end

    nil
  end

  # ---------- Main post fetcher (cascade) ----------

  def get_post(post_id, quality = "1080")
    media_id = get_media_id(post_id)

    if media_id
      # Try mobile API with bearer
      if @bearer.present?
        data = fetch_mobile_api(media_id)
        result = extract_new_post(data, post_id)
        return result if result
      end

      # Try mobile API without auth
      data = fetch_mobile_api(media_id)
      result = extract_new_post(data, post_id)
      return result if result

      # Try mobile API with cookie
      if @cookie.present?
        data = fetch_mobile_api(media_id, use_cookie: true)
        result = extract_new_post(data, post_id)
        return result if result
      end
    end

    # Try GraphQL first (best for carousels — returns all items)
    gql_data = fetch_graphql(post_id)
    gql_result = extract_old_post(gql_data, post_id)
    return gql_result if gql_result

    # Try GraphQL with cookie
    if @cookie.present?
      gql_data2 = fetch_graphql(post_id, use_cookie: true)
      gql_result2 = extract_old_post(gql_data2, post_id)
      return gql_result2 if gql_result2
    end

    # Fallback to embed scraping
    embed_result = fetch_embed(post_id)
    if embed_result
      if embed_result[:type] == "embed_json"
        result = extract_old_post(embed_result[:data], post_id)
        return result if result
      else
        return {
          status: "redirect",
          url: embed_result[:url],
          filename: "instagram_#{post_id}.#{embed_result[:type] == 'video' ? 'mp4' : 'jpg'}"
        }
      end
    end

    # Fallback to embed with cookie
    if @cookie.present?
      embed_result2 = fetch_embed(post_id, use_cookie: true)
      if embed_result2
        if embed_result2[:type] == "embed_json"
          result = extract_old_post(embed_result2[:data], post_id)
          return result if result
        else
          return {
            status: "redirect",
            url: embed_result2[:url],
            filename: "instagram_#{post_id}.#{embed_result2[:type] == 'video' ? 'mp4' : 'jpg'}"
          }
        end
      end
    end

    error_result("fetch.fail", "Could not fetch this content. Please try again.")
  end

  # ---------- Stories fetcher ----------

  def get_story(username, story_id)
    unless @cookie.present?
      return error_result("auth.required", "Instagram cookies are required to download stories")
    end

    profile_data = fetch_json(
      "https://www.instagram.com/api/v1/users/web_profile_info/?username=#{username}",
      headers: COMMON_HEADERS.merge("cookie" => @cookie, "x-ig-www-claim" => @ig_www_claim)
    )

    user_id = profile_data&.dig("data", "user", "id")
    return error_result("fetch.fail", "Could not find user") unless user_id

    dtsg = fetch_dtsg
    return error_result("fetch.fail", "Could not get DTSG token") unless dtsg

    body = URI.encode_www_form(
      variables: { reel_ids_arr: [ user_id ] }.to_json,
      doc_id: STORIES_DOC_ID,
      fb_dtsg: dtsg
    )

    stories_data = fetch_json(
      "https://www.instagram.com/api/graphql/",
      headers: COMMON_HEADERS.merge(
        "content-type" => "application/x-www-form-urlencoded",
        "cookie" => @cookie,
        "x-ig-www-claim" => @ig_www_claim
      ),
      method: :post, body: body
    )

    reels = stories_data&.dig("data", "xdt_api__v1__feed__reels_media", "reels_media")
    return error_result("fetch.empty", "No stories found") unless reels&.any?

    stories = reels[0]["items"] || []

    if story_id && story_id != "0"
      story = stories.find { |s| s["pk"].to_s == story_id || s["id"].to_s.include?(story_id) }
      return error_result("fetch.empty", "Story not found") unless story

      if story["video_versions"]&.any?
        best = pick_best_video(story["video_versions"])
        return { status: "redirect", url: best&.[]("url"), filename: "instagram_story_#{username}_#{story_id}.mp4" }
      end

      return {
        status: "redirect",
        url: story.dig("image_versions2", "candidates", 0, "url"),
        filename: "instagram_story_#{username}_#{story_id}.jpg"
      }
    end

    # Return all stories
    picker = stories.filter_map do |story|
      if story["video_versions"]&.any?
        best = pick_best_video(story["video_versions"])
        { type: "video", url: best&.[]("url"), thumb: story.dig("image_versions2", "candidates", 0, "url"), timestamp: story["taken_at"] }
      else
        url = story.dig("image_versions2", "candidates", 0, "url")
        { type: "photo", url: url, thumb: url, timestamp: story["taken_at"] }
      end
    end.select { |i| i[:url] }

    { status: "picker", picker: picker }
  end
end
