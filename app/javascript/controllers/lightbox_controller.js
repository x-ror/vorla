import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { items: Array, index: Number }

  connect() {
    this._onKeydown = (e) => {
      if (e.key === "Escape") this.close()
      if (e.key === "ArrowRight") this.next()
      if (e.key === "ArrowLeft") this.prev()
    }
  }

  indexValueChanged() {
    if (this.indexValue >= 0) this.show()
  }

  open(e) {
    if (e.target.closest('.media-checkbox')) return
    this.indexValue = parseInt(e.currentTarget.dataset.index)
  }

  show() {
    const item = this.itemsValue[this.indexValue]
    if (!item) return

    if (!this.overlay) this._createOverlay()
    
    const container = this.overlay.querySelector(".lightbox-content")
    container.innerHTML = "" // Clear previous

    const media = item.type === "video" ? this._buildVideo(item.url) : this._buildImg(item.url || item.thumb)
    container.appendChild(media)

    this.overlay.querySelector(".lightbox-counter").textContent = `${this.indexValue + 1} / ${this.itemsValue.length}`
    this.overlay.classList.add("active")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this._onKeydown)
  }

  close() {
    this.overlay?.classList.remove("active")
    this.overlay?.querySelectorAll("video").forEach(v => v.pause())
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this._onKeydown)
    this.indexValue = -1
  }

  next() { if (this.indexValue < this.itemsValue.length - 1) this.indexValue++ }
  prev() { if (this.indexValue > 0) this.indexValue-- }

  _createOverlay() {
    this.overlay = document.createElement("div")
    this.overlay.className = "lightbox-overlay"
    this.overlay.innerHTML = `
      <button class="lightbox-close">&times;</button>
      <div class="lightbox-content"></div>
      <div class="lightbox-footer">
        <button class="lightbox-prev">&#8249;</button>
        <span class="lightbox-counter"></span>
        <button class="lightbox-next">&#8250;</button>
      </div>`
    
    this.overlay.querySelector(".lightbox-close").onclick = () => this.close()
    this.overlay.querySelector(".lightbox-prev").onclick = () => this.prev()
    this.overlay.querySelector(".lightbox-next").onclick = () => this.next()
    this.element.appendChild(this.overlay)
  }

  _buildVideo(src) {
    const v = document.createElement("video")
    v.src = src; v.controls = true; v.autoplay = true; return v
  }

  _buildImg(src) {
    const i = document.createElement("img")
    i.src = src; return i
  }

  disconnect() { this.overlay?.remove() }
}