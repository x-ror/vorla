import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topic", "submitBtn", "error", "result"]

  connect() {
    this._abortController = null
  }

  disconnect() {
    this._abortController?.abort()
  }

  selectTopic(event) {
    this.topicTarget.value = event.currentTarget.dataset.topic
    this.generate()
  }

  async generate(event) {
    event?.preventDefault()
    const topic = this.topicTarget.value.trim()
    if (!topic) return

    this.hideError()
    this.resultTarget.style.display = "none"
    this.submitBtnTarget.disabled = true

    this._abortController?.abort()
    this._abortController = new AbortController()

    try {
      const response = await fetch("/api/hashtags", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topic }),
        signal: this._abortController.signal
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message)

      const hashtags = data.hashtags || []
      if (hashtags.length === 0) {
        this.showError("No hashtags found for this topic")
        return
      }

      this._hashtags = hashtags
      this.resultTarget.style.display = "block"
      this.resultTarget.innerHTML = ""
      this.resultTarget.appendChild(this._buildResult(hashtags))
    } catch (err) {
      if (err.name === "AbortError") return
      this.showError(err.message || "Failed to generate hashtags")
    } finally {
      this.submitBtnTarget.disabled = false
      document.dispatchEvent(new CustomEvent("usage:updated"))
    }
  }

  _buildResult(hashtags) {
    const wrapper = document.createElement("div")
    wrapper.className = "hashtags-result animate-slide-up"

    const header = document.createElement("div")
    header.className = "hashtags-header"
    const h3 = document.createElement("h3")
    h3.textContent = `${hashtags.length} hashtags generated`
    const copyBtn = document.createElement("button")
    copyBtn.type = "button"
    copyBtn.className = "copy-btn"
    copyBtn.textContent = "Copy All"
    copyBtn.dataset.action = "click->hashtags#copyAll"
    header.append(h3, copyBtn)

    const cloud = document.createElement("div")
    cloud.className = "hashtags-cloud"

    hashtags.forEach(h => {
      const chip = document.createElement("div")
      chip.className = "hashtag-chip"

      const tag = document.createElement("span")
      tag.className = "tag"
      tag.textContent = `#${h.tag}`
      chip.appendChild(tag)

      if (h.popularity) {
        const pop = document.createElement("span")
        pop.className = `popularity popularity-${h.popularity}`
        pop.textContent = h.popularity
        chip.appendChild(pop)
      }

      cloud.appendChild(chip)
    })

    const tip = document.createElement("div")
    tip.className = "hashtags-tip"
    const tipIcon = document.createElement("span")
    tipIcon.textContent = "\u2728"
    const tipText = document.createElement("span")
    tipText.textContent = "Mix high, medium, and low popularity hashtags for best results"
    tip.append(tipIcon, tipText)

    wrapper.append(header, cloud, tip)
    return wrapper
  }

  async copyAll() {
    if (!this._hashtags) return
    const text = this._hashtags.map(h => `#${h.tag}`).join(" ")
    const btn = this.resultTarget.querySelector(".copy-btn")

    try {
      await navigator.clipboard.writeText(text)
      if (btn) {
        btn.textContent = "Copied!"
        setTimeout(() => btn.textContent = "Copy All", 2000)
      }
    } catch {
      if (btn) btn.textContent = "Copy failed"
      setTimeout(() => { if (btn) btn.textContent = "Copy All" }, 2000)
    }
  }

  showError(msg) { this.errorTarget.textContent = msg; this.errorTarget.style.display = "flex" }
  hideError() { this.errorTarget.style.display = "none" }
}
