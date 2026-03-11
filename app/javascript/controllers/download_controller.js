import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "submitBtn", "submitText", "spinner", "error", "result", "dlSelectedBtn", "selectedCount"]

  connect() {
    this._abortController = null
    const urlParam = new URLSearchParams(window.location.search).get("url")
    if (urlParam && this.urlTarget.value) {
      this.process()
    }
  }

  disconnect() {
    this._abortController?.abort()
  }

  async process(event) {
    event?.preventDefault()
    const url = this.urlTarget.value.trim()
    if (!url) return

    this.toggleState(true)
    this._abortController?.abort()
    this._abortController = new AbortController()

    try {
      const response = await fetch("/api/download", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url }),
        signal: this._abortController.signal
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.message || "Download failed")

      this.render(data)
    } catch (err) {
      if (err.name === "AbortError") return
      this.showError(err.message || "Something went wrong.")
    } finally {
      this.toggleState(false)
    }
  }

  render(data) {
    this.resultTarget.style.display = "block"
    this.resultTarget.innerHTML = ""

    if (data.status === "picker") {
      const items = data.picker || []
      if (items.length === 0) return this.showError("No media found.")

      const lightbox = this.application.getControllerForElementAndIdentifier(this.element, "lightbox")
      if (lightbox) lightbox.itemsValue = items

      this.pickerItems = items
      this.resultTarget.appendChild(this._buildPickerHeader(items.length))
      this.resultTarget.appendChild(this._buildMediaGrid(items))
    } else {
      this.resultTarget.appendChild(this._buildSingleResult(data))
    }
  }

  _buildMediaGrid(items) {
    const grid = document.createElement("div")
    grid.className = "media-grid animate-slide-up"

    items.forEach((item, i) => {
      const card = document.createElement("div")
      card.className = "media-card"

      const preview = document.createElement("div")
      preview.className = "preview"

      // Click anywhere on preview opens lightbox, except checkbox
      preview.addEventListener("click", (e) => {
        if (e.target.closest(".media-checkbox")) return
        const lightbox = this.application.getControllerForElementAndIdentifier(this.element, "lightbox")
        if (lightbox) lightbox.indexValue = i
      })

      const label = document.createElement("label")
      label.className = "media-checkbox"
      label.addEventListener("click", (e) => e.stopPropagation())

      const cb = document.createElement("input")
      cb.type = "checkbox"
      cb.dataset.action = "change->download#updateSelection"
      cb.dataset.index = i

      const checkmark = document.createElement("span")
      checkmark.className = "checkmark"

      label.append(cb, checkmark)
      preview.appendChild(label)

      if (item.thumb) {
        const img = document.createElement("img")
        img.src = item.thumb
        img.alt = `Preview ${i + 1}`
        preview.appendChild(img)
      }

      const badge = document.createElement("span")
      badge.className = "type-badge"
      badge.textContent = item.type
      preview.appendChild(badge)

      const dlLink = document.createElement("a")
      dlLink.href = item.url
      dlLink.download = `x-ror-${i + 1}`
      dlLink.target = "_blank"
      dlLink.className = "dl-btn"
      dlLink.textContent = "Download"

      card.append(preview, dlLink)
      grid.appendChild(card)
    })
    return grid
  }

  _buildPickerHeader(count) {
    const header = document.createElement("div")
    header.className = "picker-header animate-slide-up"

    const h3 = document.createElement("h3")
    h3.textContent = `${count} items found`

    const actions = document.createElement("div")
    actions.className = "picker-actions"

    const selectAllBtn = document.createElement("button")
    selectAllBtn.type = "button"
    selectAllBtn.className = "picker-select-all"
    selectAllBtn.textContent = "Select All"
    selectAllBtn.dataset.action = "click->download#toggleAll"

    const dlBtn = document.createElement("button")
    dlBtn.className = "btn btn-primary btn-sm"
    dlBtn.dataset.action = "click->download#downloadSelected"
    dlBtn.dataset.downloadTarget = "dlSelectedBtn"
    dlBtn.disabled = true

    const countSpan = document.createElement("span")
    countSpan.dataset.downloadTarget = "selectedCount"
    countSpan.textContent = "0"

    dlBtn.append("Download Selected (", countSpan, ")")
    actions.append(selectAllBtn, dlBtn)
    header.append(h3, actions)
    return header
  }

  _buildSingleResult(data) {
    const card = document.createElement("div")
    card.className = "result-card animate-slide-up"

    const info = document.createElement("div")
    info.className = "result-info"

    const meta = document.createElement("div")
    meta.className = "result-meta"

    const icon = document.createElement("div")
    icon.className = "result-icon"
    icon.textContent = "\u2713"

    const textWrap = document.createElement("div")
    const h3 = document.createElement("h3")
    h3.textContent = "Ready to download"
    const filename = document.createElement("p")
    filename.className = "filename"
    filename.textContent = data.filename || "media file"
    textWrap.append(h3, filename)

    meta.append(icon, textWrap)

    const link = document.createElement("a")
    link.href = data.url
    link.download = data.filename || ""
    link.className = "btn btn-primary"
    link.target = "_blank"
    link.textContent = "Download"

    info.append(meta, link)
    card.appendChild(info)
    return card
  }

  // --- Selection Logic ---

  updateSelection() {
    if (!this.hasSelectedCountTarget) return
    const count = this.resultTarget.querySelectorAll("input:checked").length
    this.selectedCountTarget.textContent = count
    this.dlSelectedBtnTarget.disabled = count === 0
  }

  toggleAll() {
    const checkboxes = this.resultTarget.querySelectorAll('input[type="checkbox"]')
    const allChecked = Array.from(checkboxes).every(cb => cb.checked)
    checkboxes.forEach(cb => cb.checked = !allChecked)
    this.updateSelection()
  }

  async downloadSelected() {
    const selected = Array.from(this.resultTarget.querySelectorAll("input:checked"))
    for (const cb of selected) {
      const i = parseInt(cb.dataset.index)
      const item = this.pickerItems[i]
      if (!item) continue
      const link = document.createElement("a")
      link.href = item.url
      link.download = `x-ror-${i + 1}`
      link.target = "_blank"
      link.click()
      await new Promise(r => setTimeout(r, 600))
    }
  }

  // --- Helpers ---

  toggleState(loading) {
    this.submitBtnTarget.disabled = loading
    this.submitTextTarget.style.display = loading ? "none" : "inline"
    this.spinnerTarget.style.display = loading ? "inline-block" : "none"
    if (loading) {
      this.errorTarget.style.display = "none"
      this.resultTarget.style.display = "none"
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.style.display = "flex"
  }
}
