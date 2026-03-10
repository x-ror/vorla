import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["username", "submitBtn", "error", "result"]

  async fetch(event) {
    event.preventDefault()
    let username = this.usernameTarget.value.trim().replace(/^@/, "")
    if (!username) return

    if (username.includes("instagram.com")) {
      try {
        const url = new URL(username.startsWith("http") ? username : `https://${username}`)
        username = url.pathname.replace(/^\//, "").replace(/\/$/, "")
      } catch { /* use as-is */ }
    }

    this.hideError()
    this.resultTarget.style.display = "none"
    this.submitBtnTarget.disabled = true

    try {
      const response = await fetch("/api/profile_picture", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username })
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message || "Profile not found")

      this.resultTarget.style.display = "block"
      this.resultTarget.innerHTML = `
        <div class="pfp-result animate-slide-up">
          <div class="pfp-preview">
            <img src="${data.hdUrl}" alt="${data.username}'s profile picture">
          </div>
          <div class="pfp-info">
            <h3>@${data.username}</h3>
            ${data.fullName ? `<p style="font-size:0.9rem;color:var(--text-secondary);margin-top:2px;">${data.fullName}</p>` : ""}
            <p class="resolution">Full HD resolution</p>
          </div>
          <a href="${data.hdUrl}" download="${data.username}_profile_picture.jpg" target="_blank" class="btn btn-primary btn-lg" style="width:100%;">
            Download HD
          </a>
        </div>`
    } catch (err) {
      this.showError(err.message || "Could not find that profile.")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
