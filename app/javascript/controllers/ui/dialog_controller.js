import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "modal", "content", "closeButton"]

  open() {
    document.body.classList.add("overflow-hidden")
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.dataset.state = "open"
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this.modalTarget.dataset.state = "open"
    }
    if (this.hasContentTarget) {
      this.contentTarget.classList.add("overflow-y-scroll", "h-full")
    }
  }

  close() {
    document.body.classList.remove("overflow-hidden")
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.dataset.state = "closed"
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.dataset.state = "closed"
    }
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove("overflow-y-scroll", "h-full")
    }
  }

  toggle() {
    const visible = this.dialogTarget.dataset.state !== "closed"
    visible ? this.close() : this.open()
  }
}
