import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "submitBtn", "submitText", "spinner", "error", "result"]

  connect() {
    const urlParam = new URLSearchParams(window.location.search).get("url")
    if (urlParam && this.urlTarget.value) {
      this.process(new Event("submit"))
    }
    this._onKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    this.closeLightbox()
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
      this.pickerItems = data.picker

      let html = `<div class="picker-header animate-slide-up">
        <h3>${data.picker.length} items found</h3>
        <div class="picker-actions">
          <button type="button" data-action="click->download#toggleAll" class="picker-select-all">Select All</button>
          <button type="button" data-action="click->download#downloadSelected" class="btn btn-primary btn-sm" data-download-target="dlSelectedBtn" disabled>
            Download Selected (<span data-download-target="selectedCount">0</span>)
          </button>
        </div>
      </div>`
      html += `<div class="media-grid animate-slide-up">`
      data.picker.forEach((item, i) => {
        html += `
          <div class="media-card" data-index="${i}">
            <div class="preview" data-action="click->download#openLightbox" data-item-index="${i}">
              <label class="media-checkbox" data-action="click->download#stopProp">
                <input type="checkbox" data-action="change->download#updateSelection" data-index="${i}">
                <span class="checkmark"></span>
              </label>
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

  // --- Lightbox ---

  openLightbox(event) {
    if (event.target.closest('.media-checkbox')) return
    const index = parseInt(event.currentTarget.dataset.itemIndex)
    this.showLightboxAt(index)
  }

  showLightboxAt(index) {
    this.lightboxIndex = index
    const item = this.pickerItems[index]
    if (!item) return

    let overlay = document.getElementById("lightbox-overlay")
    if (!overlay) {
      overlay = document.createElement("div")
      overlay.id = "lightbox-overlay"
      overlay.className = "lightbox-overlay"
      overlay.innerHTML = `
        <button class="lightbox-close" data-action="click->download#closeLightbox">&times;</button>
        <button class="lightbox-prev" data-action="click->download#prevLightbox">&#8249;</button>
        <button class="lightbox-next" data-action="click->download#nextLightbox">&#8250;</button>
        <div class="lightbox-content">
          <img class="lightbox-img" src="" alt="">
        </div>
        <div class="lightbox-footer">
          <span class="lightbox-counter"></span>
          <a class="btn btn-primary btn-sm" target="_blank">Download</a>
        </div>`
      overlay.addEventListener("click", (e) => {
        if (e.target === overlay) this.closeLightbox()
      })
      document.body.appendChild(overlay)
    }

    const img = overlay.querySelector(".lightbox-img")
    const counter = overlay.querySelector(".lightbox-counter")
    const dlLink = overlay.querySelector(".lightbox-footer a")

    img.src = item.url || item.thumb
    counter.textContent = `${index + 1} / ${this.pickerItems.length}`
    dlLink.href = item.url
    dlLink.download = `vorla-${index + 1}`

    overlay.classList.add("active")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this._onKeydown)

    // Update prev/next visibility
    overlay.querySelector(".lightbox-prev").style.display = index > 0 ? "" : "none"
    overlay.querySelector(".lightbox-next").style.display = index < this.pickerItems.length - 1 ? "" : "none"
  }

  closeLightbox() {
    const overlay = document.getElementById("lightbox-overlay")
    if (overlay) {
      overlay.classList.remove("active")
      document.body.style.overflow = ""
      document.removeEventListener("keydown", this._onKeydown)
    }
  }

  prevLightbox(event) {
    event?.stopPropagation()
    if (this.lightboxIndex > 0) this.showLightboxAt(this.lightboxIndex - 1)
  }

  nextLightbox(event) {
    event?.stopPropagation()
    if (this.lightboxIndex < this.pickerItems.length - 1) this.showLightboxAt(this.lightboxIndex + 1)
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.closeLightbox()
    if (event.key === "ArrowLeft") this.prevLightbox()
    if (event.key === "ArrowRight") this.nextLightbox()
  }

  stopProp(event) {
    event.stopPropagation()
  }

  // --- Selection ---

  updateSelection() {
    const count = this.selectedCount
    this.selectedCountTarget.textContent = count
    this.dlSelectedBtnTarget.disabled = count === 0
  }

  get selectedCount() {
    return this.resultTarget.querySelectorAll('.media-checkbox input:checked').length
  }

  get selectedIndices() {
    return Array.from(this.resultTarget.querySelectorAll('.media-checkbox input:checked'))
      .map(cb => parseInt(cb.dataset.index))
  }

  toggleAll() {
    const checkboxes = this.resultTarget.querySelectorAll('.media-checkbox input')
    const allChecked = this.selectedCount === checkboxes.length
    checkboxes.forEach(cb => cb.checked = !allChecked)
    this.updateSelection()
  }

  async downloadSelected() {
    const indices = this.selectedIndices
    if (indices.length === 0) return

    for (const i of indices) {
      const item = this.pickerItems[i]
      if (!item) continue

      const link = document.createElement("a")
      link.href = item.url
      link.download = `vorla-${i + 1}`
      link.target = "_blank"
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)

      if (indices.length > 1) {
        await new Promise(r => setTimeout(r, 500))
      }
    }
  }

  // --- Helpers ---

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
