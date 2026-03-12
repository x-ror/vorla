module SeoHelper
  SITE_NAME = "X-ROR".freeze
  DEFAULT_DESCRIPTION = "Download Instagram photos, videos, reels, stories and more. The fastest and cleanest Instagram downloader.".freeze
  DEFAULT_OG_IMAGE = "/og-default.png".freeze
  MAX_TITLE_LENGTH = 60
  MAX_DESCRIPTION_LENGTH = 160

  # --- Title ---

  def seo_title(title = nil)
    raw = title || content_for(:seo_title) || content_for(:title) || SITE_NAME
    truncate(strip_tags(raw.to_s.strip), length: MAX_TITLE_LENGTH, omission: "")
  end

  # --- Description ---

  def seo_description(description = nil)
    raw = description || content_for(:seo_description) || DEFAULT_DESCRIPTION
    truncate(strip_tags(raw.to_s.strip), length: MAX_DESCRIPTION_LENGTH, omission: "")
  end

  # --- Keywords ---

  def seo_keywords
    content_for(:seo_keywords) || "instagram downloader, download instagram, instagram video downloader, instagram reels downloader, instagram stories"
  end

  # --- Canonical URL ---

  def canonical_url
    content_for(:canonical_url).presence || request.original_url.split("?").first
  end

  # --- Open Graph tags ---

  def og_tags(overrides = {})
    defaults = {
      title: seo_title,
      description: seo_description,
      url: canonical_url,
      image: seo_og_image,
      type: "website",
      site_name: SITE_NAME
    }
    tags = defaults.merge(overrides.compact)

    safe_join([
      tag.meta(property: "og:title", content: tags[:title]),
      tag.meta(property: "og:description", content: tags[:description]),
      tag.meta(property: "og:url", content: tags[:url]),
      tag.meta(property: "og:image", content: tags[:image]),
      tag.meta(property: "og:type", content: tags[:type]),
      tag.meta(property: "og:site_name", content: tags[:site_name])
    ], "\n")
  end

  # --- Twitter Card tags ---

  def twitter_card_tags(overrides = {})
    defaults = {
      card: "summary_large_image",
      title: seo_title,
      description: seo_description,
      image: seo_og_image
    }
    tags = defaults.merge(overrides.compact)

    safe_join([
      tag.meta(name: "twitter:card", content: tags[:card]),
      tag.meta(name: "twitter:title", content: tags[:title]),
      tag.meta(name: "twitter:description", content: tags[:description]),
      tag.meta(name: "twitter:image", content: tags[:image])
    ], "\n")
  end

  # --- JSON-LD structured data ---

  def json_ld(data)
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end

  def website_json_ld
    json_ld({
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => SITE_NAME,
      "url" => root_url,
      "description" => DEFAULT_DESCRIPTION,
      "potentialAction" => {
        "@type" => "SearchAction",
        "target" => {
          "@type" => "EntryPoint",
          "urlTemplate" => "#{download_url}?url={search_term_string}"
        },
        "query-input" => "required name=search_term_string"
      }
    })
  end

  def web_application_json_ld(name:, description:, url:)
    json_ld({
      "@context" => "https://schema.org",
      "@type" => "WebApplication",
      "name" => name,
      "description" => description,
      "url" => url,
      "applicationCategory" => "MultimediaApplication",
      "operatingSystem" => "All",
      "offers" => {
        "@type" => "Offer",
        "price" => "0",
        "priceCurrency" => "USD"
      },
      "provider" => {
        "@type" => "Organization",
        "name" => SITE_NAME,
        "url" => root_url
      }
    })
  end

  def faq_json_ld(questions)
    json_ld({
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => questions.map { |q|
        {
          "@type" => "Question",
          "name" => q[:question],
          "acceptedAnswer" => {
            "@type" => "Answer",
            "text" => q[:answer]
          }
        }
      }
    })
  end

  # --- Pagination ---

  def pagination_links(prev_url: nil, next_url: nil)
    links = []
    links << tag.link(rel: "prev", href: prev_url) if prev_url
    links << tag.link(rel: "next", href: next_url) if next_url
    safe_join(links, "\n")
  end

  private

  def seo_og_image
    image = content_for(:seo_image).presence
    return image if image

    if defined?(root_url)
      "#{root_url.chomp('/')}#{DEFAULT_OG_IMAGE}"
    else
      DEFAULT_OG_IMAGE
    end
  end
end
