import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["username", "submitBtn", "error", "result"]

  async fetch(event) {
    event.preventDefault()
    let username = this.usernameTarget.value.trim().replace(/^@/, "")
    if (!username) return

    // Handle URLs
    if (username.includes("instagram.com")) {
      try {
        const url = new URL(username.startsWith("http") ? username : `https://${username}`)
        const parts = url.pathname.split("/").filter(Boolean)
        username = parts[0] === "stories" && parts[1] ? parts[1] : parts[0]
      } catch { /* use as-is */ }
    }

    this.hideError()
    this.resultTarget.style.display = "none"
    this.submitBtnTarget.disabled = true

    try {
      const response = await fetch("/api/stories", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username })
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message)

      const stories = data.stories || []
      if (stories.length === 0) {
        this.showError("No active stories found for this user")
        return
      }

      this.resultTarget.style.display = "block"
      let html = `<div class="stories-grid animate-slide-up">`
      stories.forEach((story, i) => {
        html += `
          <div class="story-card">
            <div class="story-preview">
              ${story.thumbnail ? `<img src="${story.thumbnail}" alt="Story ${i + 1}">` : `<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;color:var(--text-muted);">Story</div>`}
            </div>
            <a href="${story.url}" download="story-${i + 1}" target="_blank" class="dl-btn" style="display:flex;align-items:center;justify-content:center;gap:6px;width:100%;padding:10px;font-size:0.8rem;font-weight:600;color:var(--teal);">
              Download
            </a>
          </div>`
      })
      html += `</div>`
      this.resultTarget.innerHTML = html
    } catch (err) {
      this.showError(err.message || "Failed to fetch stories")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
