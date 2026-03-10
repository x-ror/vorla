import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "submitBtn", "result"]

  selectCategory(event) {
    this.element.querySelectorAll(".cat-pill").forEach(el => el.classList.remove("active"))
    event.currentTarget.classList.add("active")
  }

  async search(event) {
    event.preventDefault()
    const query = this.queryTarget.value.trim()
    if (!query) return

    this.submitBtnTarget.disabled = true

    // Simulated search - replace with real API
    await new Promise(r => setTimeout(r, 800))

    this.resultTarget.innerHTML = `
      <div class="animate-slide-up" style="display:flex;flex-direction:column;gap:10px;">
        <div class="influencer-card">
          <div class="inf-avatar">
            <div class="avatar-placeholder">E</div>
          </div>
          <div class="inf-info">
            <h3>@example_influencer</h3>
            <p>Example Influencer</p>
          </div>
          <div class="inf-stats">
            <div class="inf-stat">&#128101; 125K</div>
            <div class="inf-stat">&#8599; 4.2%</div>
          </div>
          <span class="inf-category">lifestyle</span>
        </div>
      </div>`

    this.submitBtnTarget.disabled = false
  }
}
