import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    if (!this.hasConsent()) {
      this.bannerTarget.style.display = "block"
    }
  }

  acceptAll() {
    this.setConsent("all")
    this.hideBanner()
  }

  rejectAll() {
    this.setConsent("essential")
    this.hideBanner()
  }

  hasConsent() {
    return document.cookie.split(";").some(c => c.trim().startsWith("cookie_consent="))
  }

  setConsent(level) {
    const expires = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toUTCString()
    document.cookie = `cookie_consent=${level}; expires=${expires}; path=/; SameSite=Lax`
  }

  hideBanner() {
    this.bannerTarget.style.display = "none"
  }
}
