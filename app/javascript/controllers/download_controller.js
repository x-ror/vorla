import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "submitBtn", "submitText", "spinner", "error", "result"]

  connect() {
    const urlParam = new URLSearchParams(window.location.search).get("url")
    if (urlParam && this.urlTarget.value) {
      this.process(new Event("submit"))
    }
  }

  async process(event) {
    event.preventDefault()
    const url = this.urlTarget.value.trim()
    if (!url) return

    this.hideError()
    this.hideResult()
    this.setLoading(true)

    try {
      const response = await fetch("/api/download", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url })
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message || "Download failed")

      this.showResult(data)
    } catch (err) {
      this.showError(err.message || "Something went wrong. Please try again.")
    } finally {
      this.setLoading(false)
    }
  }

  showResult(data) {
    this.resultTarget.style.display = "block"

    if (data.status === "redirect" || data.status === "tunnel") {
      this.resultTarget.innerHTML = `
        <div class="result-card animate-slide-up">
          <div class="result-info">
            <div class="result-meta">
              <div class="result-icon">&#10003;</div>
              <div>
                <h3>Ready to download</h3>
                <p class="filename">${data.filename || "media file"}</p>
              </div>
            </div>
            <a href="${data.url}" download="${data.filename}" class="btn btn-primary" target="_blank">
              Download
            </a>
          </div>
        </div>`
    } else if (data.status === "picker") {
      let html = `<div class="picker-header animate-slide-up"><h3>${data.picker.length} items found</h3></div>`
      html += `<div class="media-grid animate-slide-up">`
      data.picker.forEach((item, i) => {
        html += `
          <div class="media-card">
            <div class="preview">
              ${item.thumb ? `<img src="${item.thumb}" alt="Item ${i + 1}">` : ""}
              <span class="type-badge">${item.type}</span>
            </div>
            <a href="${item.url}" download="vorla-${i + 1}" target="_blank" class="dl-btn">
              Download
            </a>
          </div>`
      })
      html += `</div>`
      this.resultTarget.innerHTML = html
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.style.display = "flex"
  }

  hideError() { this.errorTarget.style.display = "none" }
  hideResult() { this.resultTarget.style.display = "none" }

  setLoading(loading) {
    this.submitBtnTarget.disabled = loading
    this.submitTextTarget.style.display = loading ? "none" : "inline"
    this.spinnerTarget.style.display = loading ? "inline-block" : "none"
  }
}
