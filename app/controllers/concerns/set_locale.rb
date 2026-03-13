module SetLocale
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
    helper_method :available_locales, :locale_name, :locale_switch_path
  end

  private

  def switch_locale(&action)
    locale = extract_locale
    save_locale_preference(locale)
    I18n.with_locale(locale, &action)
  end

  def extract_locale
    locale_from_path ||
      locale_from_user_preference ||
      locale_from_header ||
      I18n.default_locale
  end

  # 1. URL path prefix: /uk/download
  def locale_from_path
    locale = params[:locale]
    return nil if locale.blank?

    locale.to_sym if I18n.available_locales.include?(locale.to_sym)
  end

  # 2. Logged-in user's saved preference
  def locale_from_user_preference
    return nil unless Current.session&.user&.locale.present?

    locale = Current.session.user.locale.to_sym
    locale if I18n.available_locales.include?(locale)
  end

  # 3. Accept-Language header
  def locale_from_header
    header = request.env["HTTP_ACCEPT_LANGUAGE"]
    return nil if header.blank?

    parsed = header.split(",").filter_map { |lang|
      parts = lang.strip.split(";")
      code = parts[0].strip.split("-").first.downcase
      quality = parts[1] ? parts[1].split("=").last.to_f : 1.0
      [ code.to_sym, quality ]
    }.sort_by { |_, q| -q }

    parsed.each do |code, _|
      return code if I18n.available_locales.include?(code)
    end

    nil
  end

  def save_locale_preference(locale)
    Current.session&.user&.update_column(:locale, locale.to_s) if Current.session&.user&.locale.to_s != locale.to_s
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  def available_locales
    I18n.available_locales
  end

  def locale_name(locale)
    {
      en: "English",
      uk: "Українська"
    }[locale.to_sym] || locale.to_s
  end

  # Build a path for switching locale by replacing/adding the locale prefix
  def locale_switch_path(target_locale)
    # Strip current locale prefix from path if present
    path = request.path
    current_prefix = "/#{I18n.locale}"
    base_path = if path.start_with?(current_prefix + "/")
                  path.delete_prefix(current_prefix)
    elsif path == current_prefix
                  "/"
    else
                  path
    end

    # Always include locale prefix so params[:locale] is set and
    # locale_from_path wins over locale_from_user_preference
    "/#{target_locale}#{base_path}"
  end
end
