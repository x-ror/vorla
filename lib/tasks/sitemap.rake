namespace :sitemap do
  desc "Generate sitemap and ping search engines"
  task generate_and_ping: :environment do
    Rake::Task["sitemap:refresh"].invoke
    SitemapGenerator::Sitemap.ping_search_engines
    puts "Sitemap generated and search engines pinged."
  end
end
