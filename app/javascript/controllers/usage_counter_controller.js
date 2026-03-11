import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count"]
  static values = { action: String }

  connect() {
    this.refresh()
    this.boundRefresh = () => this.refresh()
    document.addEventListener("usage:updated", this.boundRefresh)
  }

  disconnect() {
    document.removeEventListener("usage:updated", this.boundRefresh)
  }

  async refresh() {
    try {
      const response = await fetch("/api/usage")
      if (!response.ok) return

      const data = await response.json()
      const usage = data.limits[this.actionValue]
      if (!usage) return

      this.countTarget.textContent = `${usage.remaining}/${usage.limit}`

      if (usage.remaining === 0) {
        this.element.classList.add("text-destructive")
        this.element.classList.remove("text-muted-foreground")
      } else {
        this.element.classList.remove("text-destructive")
        this.element.classList.add("text-muted-foreground")
      }
    } catch {
      // silently fail
    }
  }
}
