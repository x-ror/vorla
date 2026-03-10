import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topic", "submitBtn", "error", "result"]

  selectTopic(event) {
    this.topicTarget.value = event.currentTarget.dataset.topic
    this.generate(new Event("submit"))
  }

  async generate(event) {
    event.preventDefault()
    const topic = this.topicTarget.value.trim()
    if (!topic) return

    this.hideError()
    this.resultTarget.style.display = "none"
    this.submitBtnTarget.disabled = true

    try {
      const response = await fetch("/api/hashtags", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topic })
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message)

      const hashtags = data.hashtags || []
      if (hashtags.length === 0) {
        this.showError("No hashtags found for this topic")
        return
      }

      let html = `
        <div class="hashtags-result animate-slide-up">
          <div class="hashtags-header">
            <h3>${hashtags.length} hashtags generated</h3>
            <button type="button" class="copy-btn" data-action="click->hashtags#copyAll">Copy All</button>
          </div>
          <div class="hashtags-cloud">`

      hashtags.forEach(h => {
        const popClass = h.popularity ? `popularity-${h.popularity}` : ""
        html += `
          <div class="hashtag-chip">
            <span class="tag">#${h.tag}</span>
            ${h.popularity ? `<span class="popularity ${popClass}">${h.popularity}</span>` : ""}
          </div>`
      })

      html += `</div>
          <div class="hashtags-tip">
            <span>&#10024;</span>
            <span>Mix high, medium, and low popularity hashtags for best results</span>
          </div>
        </div>`

      this.resultTarget.style.display = "block"
      this.resultTarget.innerHTML = html
      this._hashtags = hashtags
    } catch (err) {
      this.showError(err.message || "Failed to generate hashtags")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  async copyAll() {
    if (!this._hashtags) return
    const text = this._hashtags.map(h => `#${h.tag}`).join(" ")
    await navigator.clipboard.writeText(text)
    const btn = this.resultTarget.querySelector(".copy-btn")
    if (btn) {
      btn.textContent = "Copied!"
      setTimeout(() => btn.textContent = "Copy All", 2000)
    }
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
