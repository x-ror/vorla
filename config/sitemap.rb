SitemapGenerator::Sitemap.default_host = ENV.fetch("APP_URL", "https://x-ror.fun")

SitemapGenerator::Sitemap.create do
  # Home page is added automatically with priority 1.0

  # Main tool pages
  add download_path,        changefreq: "daily",   priority: 0.9
  add stories_path,         changefreq: "daily",   priority: 0.9
  add profile_picture_path, changefreq: "daily",   priority: 0.9
  add analyzer_path,        changefreq: "daily",   priority: 0.8
  add hashtags_path,        changefreq: "weekly",  priority: 0.7
  add influencers_path,     changefreq: "weekly",  priority: 0.7

  # Info pages
  add pricing_path,         changefreq: "monthly", priority: 0.6

  # Auth pages (low priority but indexable for branded searches)
  add login_path,           changefreq: "monthly", priority: 0.3
  add signup_path,          changefreq: "monthly", priority: 0.3
end
