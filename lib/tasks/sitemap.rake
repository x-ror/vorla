require "net/http"

namespace :sitemap do
  desc "Generate sitemap and ping search engines"
  task generate_and_ping: :environment do
    Rake::Task["sitemap:refresh:no_ping"].invoke

    sitemap_url = "https://x-ror.fun/sitemap.xml.gz"
    ping_urls = [
      "https://www.google.com/ping?sitemap=#{CGI.escape(sitemap_url)}",
      "https://www.bing.com/ping?sitemap=#{CGI.escape(sitemap_url)}"
    ]

    ping_urls.each do |url|
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      puts "Pinged #{uri.host}: #{response.code}"
    rescue StandardError => e
      puts "Failed to ping #{uri.host}: #{e.message}"
    end
  end
end
