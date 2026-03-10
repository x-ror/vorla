class HashtagService
  HASHTAG_DB = {
    "fashion" => [
      { tag: "fashion", popularity: "high" }, { tag: "style", popularity: "high" },
      { tag: "ootd", popularity: "high" }, { tag: "fashionblogger", popularity: "medium" },
      { tag: "streetstyle", popularity: "medium" }, { tag: "fashionista", popularity: "medium" },
      { tag: "outfitinspo", popularity: "medium" }, { tag: "lookoftheday", popularity: "low" },
      { tag: "fashiondaily", popularity: "low" }, { tag: "styleinspo", popularity: "low" },
      { tag: "whatiwore", popularity: "low" }, { tag: "fashiondiaries", popularity: "low" }
    ],
    "food" => [
      { tag: "food", popularity: "high" }, { tag: "foodie", popularity: "high" },
      { tag: "foodporn", popularity: "high" }, { tag: "instafood", popularity: "high" },
      { tag: "foodphotography", popularity: "medium" }, { tag: "homemade", popularity: "medium" },
      { tag: "foodblogger", popularity: "medium" }, { tag: "cooking", popularity: "medium" },
      { tag: "foodlover", popularity: "low" }, { tag: "delicious", popularity: "low" },
      { tag: "yummy", popularity: "low" }, { tag: "eeeeeats", popularity: "low" }
    ],
    "travel" => [
      { tag: "travel", popularity: "high" }, { tag: "travelgram", popularity: "high" },
      { tag: "wanderlust", popularity: "high" }, { tag: "travelphotography", popularity: "medium" },
      { tag: "adventure", popularity: "medium" }, { tag: "explore", popularity: "medium" },
      { tag: "traveltheworld", popularity: "medium" }, { tag: "travelblogger", popularity: "low" },
      { tag: "instatravel", popularity: "low" }, { tag: "roamtheplanet", popularity: "low" },
      { tag: "traveladdict", popularity: "low" }, { tag: "passportready", popularity: "low" }
    ],
    "fitness" => [
      { tag: "fitness", popularity: "high" }, { tag: "gym", popularity: "high" },
      { tag: "workout", popularity: "high" }, { tag: "fitnessmotivation", popularity: "medium" },
      { tag: "training", popularity: "medium" }, { tag: "fit", popularity: "medium" },
      { tag: "gymlife", popularity: "medium" }, { tag: "fitnessjourney", popularity: "low" },
      { tag: "workoutmotivation", popularity: "low" }, { tag: "gains", popularity: "low" },
      { tag: "fitlife", popularity: "low" }, { tag: "strongnotskinny", popularity: "low" }
    ],
    "photography" => [
      { tag: "photography", popularity: "high" }, { tag: "photooftheday", popularity: "high" },
      { tag: "photo", popularity: "high" }, { tag: "photographer", popularity: "medium" },
      { tag: "naturephotography", popularity: "medium" }, { tag: "portraitphotography", popularity: "medium" },
      { tag: "streetphotography", popularity: "medium" }, { tag: "photographylovers", popularity: "low" },
      { tag: "shotoniphone", popularity: "low" }, { tag: "visualcreatives", popularity: "low" },
      { tag: "moody", popularity: "low" }, { tag: "capturedoncanon", popularity: "low" }
    ],
    "tech" => [
      { tag: "tech", popularity: "high" }, { tag: "technology", popularity: "high" },
      { tag: "coding", popularity: "medium" }, { tag: "programming", popularity: "medium" },
      { tag: "developer", popularity: "medium" }, { tag: "techlife", popularity: "medium" },
      { tag: "gadgets", popularity: "low" }, { tag: "startup", popularity: "low" },
      { tag: "innovation", popularity: "low" }, { tag: "techcommunity", popularity: "low" },
      { tag: "buildinpublic", popularity: "low" }, { tag: "devlife", popularity: "low" }
    ],
    "beauty" => [
      { tag: "beauty", popularity: "high" }, { tag: "makeup", popularity: "high" },
      { tag: "skincare", popularity: "high" }, { tag: "beautyblogger", popularity: "medium" },
      { tag: "makeuplover", popularity: "medium" }, { tag: "beautytips", popularity: "medium" },
      { tag: "glam", popularity: "low" }, { tag: "skincareroutine", popularity: "low" },
      { tag: "makeuptutorial", popularity: "low" }, { tag: "beautycare", popularity: "low" },
      { tag: "naturalbeauty", popularity: "low" }, { tag: "beautycommunity", popularity: "low" }
    ],
    "lifestyle" => [
      { tag: "lifestyle", popularity: "high" }, { tag: "life", popularity: "high" },
      { tag: "instagood", popularity: "high" }, { tag: "lifestyleblogger", popularity: "medium" },
      { tag: "dailylife", popularity: "medium" }, { tag: "motivation", popularity: "medium" },
      { tag: "inspiration", popularity: "medium" }, { tag: "liveauthentic", popularity: "low" },
      { tag: "mindfulness", popularity: "low" }, { tag: "slowliving", popularity: "low" },
      { tag: "intentionalliving", popularity: "low" }, { tag: "lifestylephotography", popularity: "low" }
    ]
  }.freeze

  UNIVERSAL_TAGS = [
    { tag: "instagood", popularity: "high" }, { tag: "photooftheday", popularity: "high" },
    { tag: "love", popularity: "high" }, { tag: "beautiful", popularity: "medium" },
    { tag: "happy", popularity: "medium" }, { tag: "picoftheday", popularity: "medium" },
    { tag: "followme", popularity: "medium" }, { tag: "instadaily", popularity: "low" },
    { tag: "reels", popularity: "low" }, { tag: "viral", popularity: "low" }
  ].freeze

  def self.generate(topic)
    lower_topic = topic.downcase
    matched_tags = []

    # Find matching category
    HASHTAG_DB.each do |category, tags|
      if lower_topic.include?(category) || category.include?(lower_topic)
        matched_tags = tags.dup
        break
      end
    end

    # Partial match
    if matched_tags.empty?
      words = lower_topic.split(/\s+/)
      HASHTAG_DB.each do |category, tags|
        if words.any? { |w| category.include?(w) || w.include?(category) }
          matched_tags = tags.dup
          break
        end
      end
    end

    # Fallback
    if matched_tags.empty?
      clean = lower_topic.gsub(/\s+/, "")
      matched_tags = [
        { tag: clean, popularity: "medium" },
        { tag: "#{clean}life", popularity: "low" },
        { tag: "#{clean}daily", popularity: "low" },
        { tag: "insta#{clean}", popularity: "low" },
        { tag: "#{clean}lover", popularity: "low" },
        { tag: "#{clean}gram", popularity: "low" }
      ]
    end

    # Add universal tags
    existing_tags = matched_tags.map { |t| t[:tag] }
    additional = UNIVERSAL_TAGS.reject { |u| existing_tags.include?(u[:tag]) }.first(6)
    all_tags = (matched_tags + additional).shuffle

    all_tags.first(20)
  end
end
