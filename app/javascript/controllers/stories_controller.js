import { Controller } from "@hotwired/stimulus"
import { buildBookmarkBtn } from "helpers/bookmark_button"

export default class extends Controller {
  static targets = ["username", "submitBtn", "error", "result"]

  connect() {
    this._abortController = null
  }

  disconnect() {
    this._abortController?.abort()
  }

  async fetch(event) {
    event.preventDefault()
    let username = this.usernameTarget.value.trim().replace(/^@/, "")
    if (!username) return

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

    this._abortController?.abort()
    this._abortController = new AbortController()

    try {
      const response = await fetch("/api/stories", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username }),
        signal: this._abortController.signal
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message)

      const stories = data.stories || []
      if (stories.length === 0) {
        this.showError("No active stories found for this user")
        return
      }

      this.resultTarget.style.display = "block"
      this.resultTarget.innerHTML = ""

      const grid = document.createElement("div")
      grid.className = "stories-grid animate-slide-up"

      stories.forEach((story, i) => {
        const card = document.createElement("div")
        card.className = "story-card"

        const preview = document.createElement("div")
        preview.className = "story-preview"

        if (story.thumbnail) {
          const img = document.createElement("img")
          img.src = story.thumbnail
          img.alt = `Story ${i + 1}`
          preview.appendChild(img)
        } else {
          const placeholder = document.createElement("div")
          placeholder.className = "story-placeholder"
          placeholder.textContent = "Story"
          preview.appendChild(placeholder)
        }

        const btnRow = document.createElement("div")
        btnRow.className = "media-card-actions"

        const link = document.createElement("a")
        link.href = story.url
        link.download = `story-${i + 1}`
        link.target = "_blank"
        link.className = "dl-btn"
        link.textContent = "Download"

        btnRow.append(link, buildBookmarkBtn({ sourceUrl: `https://www.instagram.com/stories/${username}/`, mediaUrl: story.url, title: `@${username} story ${i + 1}`, mediaType: story.type || "video", author: username, postedAt: story.timestamp }))
        card.append(preview, btnRow)
        grid.appendChild(card)
      })

      this.resultTarget.appendChild(grid)
    } catch (err) {
      if (err.name === "AbortError") return
      this.showError(err.message || "Failed to fetch stories")
    } finally {
      this.submitBtnTarget.disabled = false
      document.dispatchEvent(new CustomEvent("usage:updated"))
    }
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
