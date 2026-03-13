module SetLocale
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
    helper_method :available_locales, :locale_name
  end

  private

  def switch_locale(&action)
    locale = extract_locale
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
end
