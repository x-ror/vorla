module BreadcrumbHelper
  def breadcrumbs(*crumbs)
    items = [ { name: I18n.t("breadcrumbs.home", default: "Home"), url: root_url } ] + crumbs

    nav = content_tag(:nav, aria: { label: "breadcrumb" }, class: "text-sm text-muted-foreground") do
      content_tag(:ol, class: "flex items-center gap-1.5 flex-wrap") do
        safe_join(items.each_with_index.map { |crumb, i|
          is_last = (i == items.length - 1)
          content_tag(:li, class: "flex items-center gap-1.5") do
            parts = []
            parts << content_tag(:span, "/", class: "text-muted-foreground/50", aria: { hidden: true }) if i > 0
            if is_last
              parts << content_tag(:span, crumb[:name], aria: { current: "page" }, class: "font-medium text-foreground")
            else
              parts << link_to(crumb[:name], crumb[:url], class: "transition-colors hover:text-foreground")
            end
            safe_join(parts)
          end
        })
      end
    end

    schema = breadcrumb_json_ld(items)
    safe_join([ nav, schema ], "\n")
  end

  private

  def breadcrumb_json_ld(items)
    data = {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map { |crumb, i|
        {
          "@type" => "ListItem",
          "position" => i + 1,
          "name" => crumb[:name],
          "item" => crumb[:url]
        }
      }
    }
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end
end
