module SetLocale
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
    helper_method :available_locales, :locale_name, :locale_switch_path
  end

  private

  def switch_locale(&action)
    locale = extract_locale
    # Only update if user is logged in AND the locale actually changed
    save_locale_preference(locale) if Current.session&.user && Current.session.user.locale != locale.to_s

    I18n.with_locale(locale, &action)
  end

  def extract_locale
    # We validate the locale immediately in each step to keep it DRY
    validated_locale(params[:locale]) ||
      validated_locale(Current.session&.user&.locale) ||
      locale_from_header ||
      I18n.default_locale
  end

  def validated_locale(locale)
    return nil if locale.blank?

    parsed = locale.to_sym
    I18n.available_locales.include?(parsed) ? parsed : nil
  end

  def locale_from_header
    http_accept_language.compatible_language_from(I18n.available_locales)
  rescue
    nil
  end

  def save_locale_preference(locale)
    Current.session.user.update_column(:locale, locale.to_s)
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  def available_locales
    I18n.available_locales
  end

  def locale_name(locale)
    I18n.t("languages.#{locale}", default: locale.to_s.upcase)
  end

  def locale_switch_path(target_locale)
    url_for(request.params.merge(locale: target_locale))
  end
end
